import urllib.request
import urllib.error

try:
    r = urllib.request.urlopen("http://localhost:8000/api/profile/test_user")
    print(r.status, r.read().decode())
except urllib.error.HTTPError as e:
    print(f"HTTP Error: {e.code}")
    print(e.read().decode())
except Exception as e:
    print(f"Other Error: {e}")
