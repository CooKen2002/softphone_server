from datetime import datetime, timedelta
from dateutil.relativedelta import relativedelta
import re

from .constants import *
from .utils import *


class Booking:
    def __init__(
        self,
        _id,
        sender,
        phone,
        locTo,
        locfrom,
        time,
        typeVehical,
        typeSeat,
        count,
        name,
        statusBooking,
        timeCode,
        cancel,
    ):
        self._id = _id
        self.sender = sender
        self.phone = phone
        self.locTo = locTo
        self.locfrom = locfrom
        self.time = time
        self.typeVehical = typeVehical
        self.typeSeat = typeSeat
        self.count = count
        self.name = name
        self.statusBooking = statusBooking
        self.timeCode = timeCode
        self.cancel = cancel

    def toJson(self):
        return {
            ID: self._id,
            SENDER: self.sender,
            DIEN_THOAI: self.phone,
            DIEM_DEN: self.locTo,
            DIEM_DON: self.locfrom,
            THOI_GIAN: self.time,
            LOAI_XE: self.typeVehical,
            KIEU_GHE: self.typeSeat,
            SO_LUONG: self.count,
            HO_TEN: self.name,
            STATUS_BOOKING: self.statusBooking,
            MA_THOI_GIAN: self.timeCode,
            CANCEL: self.cancel,
        }

    def fromJson(self, json={}):
        return Booking(
            json.get(ID, 0),
            json.get(SENDER, ""),
            json.get(DIEN_THOAI, ""),
            json.get(DIEM_DEN, ""),
            json.get(DIEM_DON, ""),
            json.get(THOI_GIAN, ""),
            json.get(LOAI_XE, ""),
            json.get(KIEU_GHE, ""),
            json.get(SO_LUONG, 0),
            json.get(HO_TEN, ""),
            json.get(STATUS_BOOKING, 0),
            json.get(MA_THOI_GIAN, ""),
            json.get(CANCEL, False),
        )

    def getTimeCode(self):
        if self.time is None or self.time == "":
            return ""
        dateText = parse_vietnamese_datetime(self.time)
        return dateText.strftime("%Y%m%d%H%M%S")

    def isExpired(self):
        dateCode = datetime.strptime(self.timeCode, "%Y%m%d%H%M%S")
        return datetime.now() > dateCode

    def isCancel(self):
        return self.cancel

    def getStatusBooking(self):
        return self.statusBooking
