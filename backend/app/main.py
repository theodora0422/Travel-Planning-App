import os
from typing import List, Optional
import uuid

import requests
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

load_dotenv()

app = FastAPI(title="Travel Planning API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

RAPIDAPI_KEY = os.getenv("RAPIDAPI_KEY")
GEODB_HOST = "wft-geo-db.p.rapidapi.com"
GOOGLE_PLACES_API_KEY = os.getenv("GOOGLE_PLACES_API_KEY")

def parse_city_item(item: dict) -> Optional[dict]:
    city = item.get("city")
    country = item.get("country")
    latitude = item.get("latitude")
    longitude = item.get("longitude")

    if not city or not country:
        return None

    return {
        "id": item.get("id"),
        "name": city,
        "country": country,
        "latitude": latitude,
        "longitude": longitude,
        "region": item.get("region"),
    }


def fetch_cities(query: str, limit: int = 6) -> List[dict]:
    if not RAPIDAPI_KEY:
        raise HTTPException(status_code=500, detail="RAPIDAPI_KEY is missing")

    url = f"https://{GEODB_HOST}/v1/geo/cities"
    headers = {
        "X-RapidAPI-Key": RAPIDAPI_KEY,
        "X-RapidAPI-Host": GEODB_HOST,
    }
    params = {
        "namePrefix": query,
        "limit": limit,
        "sort": "-population",
    }

    response = requests.get(url, headers=headers, params=params, timeout=10)

    if response.status_code != 200:
        raise HTTPException(
            status_code=502,
            detail=f"Failed to fetch city data: {response.status_code} {response.text}",
        )

    data = response.json()
    cities = data.get("data", [])

    parsed = []
    seen = set()

    for item in cities:
        city_info = parse_city_item(item)
        if not city_info:
            continue

        key = (
            city_info["name"].strip().lower(),
            city_info["country"].strip().lower(),
        )
        if key in seen:
            continue

        seen.add(key)
        parsed.append(city_info)

    return parsed


@app.get("/")
def root():
    return {"message": "Travel Planning API is running"}


@app.get("/cities/autocomplete")
def cities_autocomplete(q: str = Query(..., min_length=1)):
    return fetch_cities(q, limit=6)


@app.get("/cities/validate")
def validate_city(q: str = Query(..., min_length=1)):
    results = fetch_cities(q, limit=8)
    normalized_query = q.strip().lower()

    exact_match = next(
        (city for city in results if city["name"].strip().lower() == normalized_query),
        None,
    )

    if exact_match:
        return {"valid": True, "city": exact_match}

    return {"valid": False, "city": None}

class GenerateItineraryRequest(BaseModel):
    cityName: str
    country: str
    numberOfDays: int
    tripStyle: str


def style_to_daily_limit(trip_style: str) -> int:
    style = trip_style.strip().lower()

    if style == "relaxed":
        return 3
    if style == "packed":
        return 5
    return 4  # balanced


def estimate_duration(primary_type: str, title: str) -> int:
    t = (primary_type or "").lower()
    title_lower = (title or "").lower()

    if "museum" in t:
        return 120
    if "art_gallery" in t:
        return 90
    if "park" in t or "tourist_attraction" in t:
        return 90
    if "restaurant" in t:
        return 75
    if "cafe" in t:
        return 45
    if "church" in t or "hindu_temple" in t or "mosque" in t or "synagogue" in t:
        return 60
    if "point_of_interest" in t:
        return 80
    if "viewpoint" in title_lower:
        return 60

    return 75


def is_food_type(primary_type: str) -> bool:
    t = (primary_type or "").lower()
    return "restaurant" in t or "cafe" in t


def is_good_itinerary_place(primary_type: str, title: str) -> bool:
    t = (primary_type or "").lower()
    title_lower = (title or "").lower()

    blocked_keywords = [
        "jewelry",
        "electronics",
        "supermarket",
        "mall",
        "repair",
        "service",
        "pharmacy",
        "bank",
        "car wash",
        "insurance",
        "hardware",
        "store",
    ]

    if any(word in title_lower for word in blocked_keywords):
        return False

    allowed_primary_types = {
        "tourist_attraction",
        "museum",
        "art_gallery",
        "park",
        "restaurant",
        "cafe",
        "church",
        "hindu_temple",
        "mosque",
        "synagogue",
        "point_of_interest",
        "historical_landmark",
        "cultural_landmark",
    }

    if t in allowed_primary_types:
        return True

    if "tourist" in t or "museum" in t or "park" in t:
        return True

    return False


def build_comments(place: dict) -> str:
    rating = place.get("rating")
    address = place.get("formattedAddress")
    primary_type = place.get("primaryTypeDisplayName", {}).get("text")

    parts = []

    if primary_type:
        parts.append(primary_type)

    if rating is not None:
        parts.append(f"Rating {rating}")

    if address:
        parts.append(address)

    if not parts:
        return "Recommended stop for your itinerary."

    return " • ".join(parts)


def place_score(place: dict) -> float:
    score = 0.0

    primary_type = (place.get("primaryType") or "").lower()
    rating = place.get("rating") or 0
    user_rating_count = place.get("userRatingCount") or 0

    if primary_type == "tourist_attraction":
        score += 100
    elif primary_type == "museum":
        score += 90
    elif primary_type == "historical_landmark":
        score += 90
    elif primary_type == "cultural_landmark":
        score += 88
    elif primary_type == "art_gallery":
        score += 80
    elif primary_type == "park":
        score += 70
    elif primary_type == "church":
        score += 65
    elif primary_type == "restaurant":
        score += 40
    elif primary_type == "cafe":
        score += 25
    elif primary_type == "point_of_interest":
        score += 50

    score += float(rating) * 10
    score += min(user_rating_count / 100.0, 30.0)

    return score

def search_google_places(query_text: str) -> List[dict]:
    if not GOOGLE_PLACES_API_KEY:
        raise HTTPException(status_code=500, detail="GOOGLE_PLACES_API_KEY is missing")

    url = "https://places.googleapis.com/v1/places:searchText"

    body = {
        "textQuery": query_text,
        "pageSize": 20,
        "languageCode": "en",
    }

    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": GOOGLE_PLACES_API_KEY,
        "X-Goog-FieldMask": ",".join([
            "places.id",
            "places.displayName",
            "places.formattedAddress",
            "places.location",
            "places.primaryType",
            "places.primaryTypeDisplayName",
            "places.rating",
            "places.userRatingCount",
        ]),
    }

    response = requests.post(url, json=body, headers=headers, timeout=15)

    if response.status_code != 200:
        raise HTTPException(
            status_code=502,
            detail=f"Google Places error: {response.status_code} {response.text}",
        )

    payload = response.json()
    return payload.get("places", [])

def google_places_autocomplete(query:str,city_name:str,country:str,session_token:str):
    if not GOOGLE_PLACES_API_KEY:
        raise HTTPException(status_code=500, detail="GOOGLE_PLACES_API_KEY is missing")
    url="https://places.googleapis.com/v1/places:autocomplete"
    body={
        "input":f"{query} {city_name} {country}".strip(),
        "languageCode":"en",
        "sessionToken": session_token,
    }
    headers={
        "Content-Type": "application/json",
        "X-Goog-Api-Key": GOOGLE_PLACES_API_KEY,
        "X-Goog-FieldMask":",".join([
            "suggestions.placePrediction.placeId",
            "suggestions.placePrediction.text",
            "suggestions.placePrediction.structuredFormat",
        ]),
    }
    response = requests.post(url,json=body,headers=headers,timeout=15)
    if response.status_code != 200:
        raise HTTPException(
            status_code=502,
            detail=f"Google Places Autocomplete error: {response.status_code} {response.text}",
        )
    payload = response.json()
    suggestions= payload.get("suggestions", [])
    results=[]
    seen=set()
    for item in suggestions:
        prediction=item.get("placePrediction")
        if not prediction:
            continue
        place_id=prediction.get("placeId")
        if not place_id or place_id in seen:
            continue
        seen.add(place_id)
        structured=prediction.get("structuredFormat",{})
        main_text=structured.get("mainText",{}).get("text") or prediction.get("text",{}).get("text") or ""
        secondary_text=structured.get("secondaryText",{}).get("text") or ""
        results.append({
            "placeId": place_id,
            "mainText":main_text,
            "secondaryText": secondary_text,
            "fullText":prediction.get("text",{}).get("text") or "",
        })
    return results

def google_place_details(place_id: str, session_token: Optional[str]=None) -> dict:
    if not GOOGLE_PLACES_API_KEY:
        raise HTTPException(status_code=500, detail="GOOGLE_PLACES_API_KEY is missing")

    url = f"https://places.googleapis.com/v1/places/{place_id}"

    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": GOOGLE_PLACES_API_KEY,
        "X-Goog-FieldMask": ",".join([
            "id",
            "displayName",
            "formattedAddress",
            "location",
            "primaryType",
            "primaryTypeDisplayName",
            "rating",
            "userRatingCount",
            "nationalPhoneNumber",
            "websiteUri",
            "googleMapsUri",
        ]),
    }

    params = {
        "languageCode": "en",
    }

    if session_token:
        params["sessionToken"] = session_token

    response = requests.get(url, headers=headers, params=params, timeout=15)

    if response.status_code != 200:
        raise HTTPException(
            status_code=502,
            detail=f"Google Place Details error: {response.status_code} {response.text}",
        )

    place = response.json()
    location = place.get("location", {}) or {}

    primary_type_display = (place.get("primaryTypeDisplayName") or {}).get("text")
    rating = place.get("rating")
    address = place.get("formattedAddress")

    comments_parts = []
    if primary_type_display:
        comments_parts.append(primary_type_display)
    if rating is not None:
        comments_parts.append(f"Rating {rating}")
    if address:
        comments_parts.append(address)

    comments = " • ".join(comments_parts) if comments_parts else "Custom activity"

    return {
        "placeId": place.get("id"),
        "title": (place.get("displayName") or {}).get("text") or "",
        "comments": comments,
        "latitude": location.get("latitude"),
        "longitude": location.get("longitude"),
        "durationMinutes": estimate_duration(
            place.get("primaryType") or "",
            (place.get("displayName") or {}).get("text") or "",
        ),
        "primaryType": place.get("primaryType"),
        "primaryTypeDisplayName": primary_type_display,
        "address": address,
        "rating": place.get("rating"),
        "userRatingCount": place.get("userRatingCount"),
        "phoneNumber": place.get("nationalPhoneNumber"),
        "websiteUri": place.get("websiteUri"),
        "googleMapsUri": place.get("googleMapsUri"),
    }

def reverse_geocode_coordinates(latitude: float, longitude: float) -> Optional[dict]:
    if not GOOGLE_PLACES_API_KEY:
        raise HTTPException(status_code=500, detail="GOOGLE_PLACES_API_KEY is missing")

    url = "https://maps.googleapis.com/maps/api/geocode/json"
    params = {
        "latlng": f"{latitude},{longitude}",
        "key": GOOGLE_PLACES_API_KEY,
    }

    response = requests.get(url, params=params, timeout=15)

    if response.status_code != 200:
        raise HTTPException(
            status_code=502,
            detail=f"Reverse geocoding error: {response.status_code} {response.text}",
        )

    payload = response.json()
    results = payload.get("results", [])

    if not results:
        return None

    first = results[0]

    return {
        "formattedAddress": first.get("formatted_address"),
        "placeId": first.get("place_id"),
    }


def search_nearby_place_from_coordinates(latitude: float, longitude: float) -> Optional[dict]:
    if not GOOGLE_PLACES_API_KEY:
        raise HTTPException(status_code=500, detail="GOOGLE_PLACES_API_KEY is missing")

    url = "https://places.googleapis.com/v1/places:searchNearby"

    body = {
        "includedTypes": [
            "tourist_attraction",
            "museum",
            "art_gallery",
            "park",
            "historical_landmark",
            "cultural_landmark",
            "restaurant",
            "cafe",
            "church",
        ],
        "maxResultCount": 5,
        "locationRestriction": {
            "circle": {
                "center": {
                    "latitude": latitude,
                    "longitude": longitude,
                },
                "radius": 120.0,
            }
        },
        "languageCode": "en",
    }

    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": GOOGLE_PLACES_API_KEY,
        "X-Goog-FieldMask": ",".join([
            "places.id",
            "places.displayName",
            "places.formattedAddress",
            "places.location",
            "places.primaryType",
            "places.primaryTypeDisplayName",
            "places.rating",
            "places.userRatingCount",
        ]),
    }

    response = requests.post(url, json=body, headers=headers, timeout=15)

    if response.status_code != 200:
        raise HTTPException(
            status_code=502,
            detail=f"Nearby Search error: {response.status_code} {response.text}",
        )

    payload = response.json()
    places = payload.get("places", [])

    if not places:
        return None

    best_place = places[0]
    location = best_place.get("location", {}) or {}

    return {
        "placeId": best_place.get("id"),
        "title": (best_place.get("displayName") or {}).get("text") or "Selected place",
        "comments": build_comments(best_place),
        "latitude": location.get("latitude"),
        "longitude": location.get("longitude"),
        "durationMinutes": estimate_duration(
            best_place.get("primaryType") or "",
            (best_place.get("displayName") or {}).get("text") or "",
        ),
        "primaryType": best_place.get("primaryType"),
        "address": best_place.get("formattedAddress"),
    }


def resolve_place_from_coordinates(latitude: float, longitude: float) -> dict:
    reverse_result = reverse_geocode_coordinates(latitude, longitude)

    if reverse_result and reverse_result.get("placeId"):
        try:
            details = google_place_details(
                place_id=reverse_result["placeId"],
                session_token=None,
            )

            details["latitude"] = latitude
            details["longitude"] = longitude

            if not details.get("comments") and reverse_result.get("formattedAddress"):
                details["comments"] = reverse_result["formattedAddress"]

            return details
        except Exception:
            pass

    nearby_place = search_nearby_place_from_coordinates(latitude, longitude)
    if nearby_place:
        return nearby_place

    return {
        "placeId": None,
        "title": "Custom activity",
        "comments": reverse_result.get("formattedAddress") if reverse_result else "Selected from map",
        "latitude": latitude,
        "longitude": longitude,
        "durationMinutes": 90,
        "primaryType": None,
        "address": reverse_result.get("formattedAddress") if reverse_result else None,
        "rating": None,
        "userRatingCount": None,
        "phoneNumber": None,
        "websiteUri": None,
        "googleMapsUri": f"https://www.google.com/maps/search/?api=1&query={latitude},{longitude}",
    }

def fetch_places_for_city(city_name: str, country: str, trip_style: str) -> List[dict]:
    city_query = f"{city_name}, {country}"

    search_queries = [
        f"top tourist attractions in {city_query}",
        f"best places to visit in {city_query}",
        f"famous landmarks in {city_query}",
        f"best museums in {city_query}",
        f"best parks in {city_query}",
        f"best viewpoints in {city_query}",
        f"best restaurants in {city_query}",
        f"best cafes in {city_query}",
    ]   
    
    raw_places = []
    seen = set()

    for query_text in search_queries:
        results = search_google_places(query_text)

        for place in results:
            name = (place.get("displayName") or {}).get("text")
            if not name:
                continue

            key = name.strip().lower()
            if key in seen:
                continue

            primary_type = place.get("primaryType") or ""
            if not is_good_itinerary_place(primary_type, name):
                continue

            seen.add(key)

            location = place.get("location", {}) or {}

            normalized_place = {
                "placeId": place.get("id"),
                "title": name,
                "durationMinutes": estimate_duration(primary_type, name),
                "comments": build_comments(place),
                "latitude": location.get("latitude"),
                "longitude": location.get("longitude"),
                "primaryType": primary_type,
                "score": place_score(place),
            }

            raw_places.append(normalized_place)

    raw_places.sort(key=lambda item: item.get("score", 0), reverse=True)
    return raw_places

def distribute_places_into_days(places: List[dict],number_of_days: int,trip_style: str,) -> List[dict]:
    per_day = style_to_daily_limit(trip_style)

    days = []
    used_titles = set()
    cursor = 0

    for day_number in range(1, number_of_days + 1):
        activities = []
        food_count = 0
        museum_count = 0
        park_count = 0
        attraction_count = 0

        
        local_cursor = cursor
        while len(activities) < per_day and local_cursor < len(places):
            place = places[local_cursor]
            local_cursor += 1

            title = place["title"]
            primary_type = (place.get("primaryType") or "").lower()

            if title in used_titles:
                continue

            if primary_type == "restaurant" and food_count >= 1:
                continue
            if primary_type == "cafe" and food_count >= 1:
                continue
            if primary_type == "museum" and museum_count >= 1:
                continue
            if primary_type == "park" and park_count >= 1:
                continue
            if primary_type == "tourist_attraction" and attraction_count >= 2:
                continue

            activities.append({
                "placeId": place["placeId"],
                "title": place["title"],
                "durationMinutes": place["durationMinutes"],
                "comments": place["comments"],
                "latitude": place["latitude"],
                "longitude": place["longitude"],
                "primaryType": place["primaryType"],
            })

            used_titles.add(title)

            if primary_type in ("restaurant", "cafe"):
                food_count += 1
            elif primary_type == "museum":
                museum_count += 1
            elif primary_type == "park":
                park_count += 1
            elif primary_type == "tourist_attraction":
                attraction_count += 1

        cursor = local_cursor

        
        if len(activities) < per_day:
            for place in places:
                if len(activities) >= per_day:
                    break

                title = place["title"]
                if title in used_titles:
                    continue

                activities.append({
                    "placeId": place["placeId"],
                    "title": place["title"],
                    "durationMinutes": place["durationMinutes"],
                    "comments": place["comments"],
                    "latitude": place["latitude"],
                    "longitude": place["longitude"],
                    "primaryType": place["primaryType"],
                })
                used_titles.add(title)

        days.append({
            "dayNumber": day_number,
            "activities": activities,
        })

    return days

def fallback_places(city_name: str) -> List[dict]:
    return [
        {
            "title": f"{city_name} city center walk",
            "durationMinutes": 90,
            "comments": "Explore the central area and discover the local atmosphere.",
            "latitude": None,
            "longitude": None,
            "primaryType": "tourist_attraction",
            "score": 80,
        },
        {
            "title": "Main landmark visit",
            "durationMinutes": 90,
            "comments": "One of the most representative attractions of the city.",
            "latitude": None,
            "longitude": None,
            "primaryType": "tourist_attraction",
            "score": 75,
        },
        {
            "title": "Museum stop",
            "durationMinutes": 120,
            "comments": "Suggested cultural stop for your default itinerary.",
            "latitude": None,
            "longitude": None,
            "primaryType": "museum",
            "score": 70,
        },
        {
            "title": "Park visit",
            "durationMinutes": 90,
            "comments": "Relaxed outdoor activity.",
            "latitude": None,
            "longitude": None,
            "primaryType": "park",
            "score": 60,
        },
        {
            "title": "Restaurant break",
            "durationMinutes": 75,
            "comments": "Try a local restaurant.",
            "latitude": None,
            "longitude": None,
            "primaryType": "restaurant",
            "score": 50,
        },
    ]


@app.post("/itinerary/generate")
def generate_itinerary(payload: GenerateItineraryRequest):
    if payload.numberOfDays < 1:
        raise HTTPException(status_code=400, detail="numberOfDays must be >= 1")

    places = fetch_places_for_city(
        city_name=payload.cityName,
        country=payload.country,
        trip_style=payload.tripStyle,
    )

    if not places:
        places = fallback_places(payload.cityName)

    days = distribute_places_into_days(
        places=places,
        number_of_days=payload.numberOfDays,
        trip_style=payload.tripStyle,
    )
    return {
        "city": {
            "name": payload.cityName,
            "country": payload.country,
        },
        "tripStyle": payload.tripStyle,
        "numberOfDays": payload.numberOfDays,
        "days": days,
    }

@app.get("/places/autocomplete")
def places_autocomplete(q: str = Query(..., min_length=1), cityName: str = Query(..., min_length=1), country: str = Query(..., min_length=1), sessionToken: str=Query(..., min_length=1)):
    return google_places_autocomplete(q, cityName, country, sessionToken)
@app.get("/places/details")
def place_details(placeId: str = Query(..., min_length=1), sessionToken: Optional[str]=Query(default=None)):
    return google_place_details(placeId, sessionToken)
@app.get("/places/from-coordinates")
def place_from_coordinates(latitude: float = Query(...), longitude: float = Query(...)):
    return resolve_place_from_coordinates(latitude, longitude)