import requests

BASE_URL = "http://192.168.1.75:3000/rasa"


def post(url="", body={}):
    # print(f"{url}\n{body}")
    response = requests.post(url, json=body)
    return response


def get(url=""):
    response = requests.get(url)
    return response
