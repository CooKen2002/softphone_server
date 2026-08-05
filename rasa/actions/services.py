from .models import *
from .http_ulti import *
from .constants import *


def createBooking(booking: Booking):
    url = f"{BASE_URL}/createBooking"
    body = booking.toJson()
    return post(url, body).json()


def seachBooking(booking: Booking):
    url = f"{BASE_URL}/seachBooking"
    body = {SENDER: booking.sender, DIEN_THOAI: booking.phone}
    return post(url, body).json()


def seachBookingBySenderAndPhone(sender, phone):
    url = f"{BASE_URL}/seachBooking"
    body = {SENDER: sender, DIEN_THOAI: phone}
    return post(url, body).json()


def cancelBooking(booking: Booking):
    url = f"{BASE_URL}/cancelBooking"
    body = {ID: booking._id}
    return post(url, body).json()


def cancelBookingById(id):
    url = f"{BASE_URL}/cancelBooking"
    body = {ID: id}
    return post(url, body).json()


def updateBooking(booking: Booking):
    url = f"{BASE_URL}/updateBooking"
    body = booking.toJson()
    return post(url, body).json()
