import requests
import json

BASE_URL = "http://localhost:8000"

def test_onboarding_persistence():
    user_id = "test_user_onboarding_final"
    
    profile_data = {
        "user_id": user_id,
        "learning_objective": "entender",
        "preferred_tone": "humor",
        "scaffolding_level": "alto",
        "selected_contexts": ["space", "gaming"],
        "specific_interests": ["Queen", "SpaceX"],
        "mastery_scores": {"algebra": 10.5},
        "error_patterns": {"sign_flip": 0.2}
    }
    
    print(f"Sending onboarding profile for {user_id}...")
    try:
        response = requests.post(f"{BASE_URL}/api/profile", json=profile_data)
        
        if response.status_code == 200:
            print("Profile saved successfully!")
            saved_data = response.json()
            print(json.dumps(saved_data, indent=2))
            
            # Verify read
            print(f"Retrieving profile for {user_id}...")
            get_response = requests.get(f"{BASE_URL}/api/profile/{user_id}")
            if get_response.status_code == 200:
                print("Profile retrieved successfully!")
                print(json.dumps(get_response.json(), indent=2))
            else:
                print(f"Error retrieving profile: {get_response.status_code}")
        else:
            print(f"Error saving profile: {response.status_code}")
            print(response.text)
    except Exception as e:
        print(f"Connection error: {e}")

if __name__ == "__main__":
    test_onboarding_persistence()
