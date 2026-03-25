import urllib.request
import urllib.error
import json

BASE_URL = "http://localhost:8000"

def test_onboarding_persistence_urllib():
    user_id = "test_user_onboarding_urllib"
    
    profile_data = {
        "user_id": user_id,
        "learning_objective": "entender",
        "preferred_tone": "humor",
        "scaffolding_level": "alto",
        "selected_contexts": ["space", "gaming"],
        "specific_interests": ["Queen", "SpaceX"],
        "difficulty_level": "alto",
        "mastery_scores": {"algebra": 10.5},
        "error_patterns": {"sign_flip": 0.2}
    }
    
    print(f"Sending onboarding profile for {user_id} via urllib...")
    
    data = json.dumps(profile_data).encode("utf-8")
    req = urllib.request.Request(
        f"{BASE_URL}/api/profile",
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    
    try:
        with urllib.request.urlopen(req) as response:
            if response.status == 200:
                print("Profile saved successfully!")
                res_body = response.read().decode("utf-8")
                print(json.dumps(json.loads(res_body), indent=2))
                
                # Verify read
                print(f"Retrieving profile for {user_id}...")
                with urllib.request.urlopen(f"{BASE_URL}/api/profile/{user_id}") as get_res:
                    if get_res.status == 200:
                        print("Profile retrieved successfully!")
                        print(json.dumps(json.loads(get_res.read().decode("utf-8")), indent=2))
                    else:
                        print(f"Error retrieving: {get_res.status}")
    except urllib.error.HTTPError as e:
        print(f"HTTP Error: {e.code}")
        print(e.read().decode("utf-8"))
    except Exception as e:
        print(f"Request error: {e}")

if __name__ == "__main__":
    test_onboarding_persistence_urllib()
