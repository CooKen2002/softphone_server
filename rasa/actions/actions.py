from typing import Any, Text, Dict, List

from rasa_sdk import Action, Tracker, FormValidationAction
from rasa_sdk.executor import CollectingDispatcher
from rasa_sdk.types import DomainDict
from rasa_sdk.events import *  # AllSlotsReset, SlotSet, Restarted
from .utils import *
from .constants import *


def fill_All_Form_Huy_Ve(ticket):
    return [
        SlotSet(SO_LUONG, None),
        SlotSet(DIEN_THOAI, ticket.get(DIEN_THOAI)),
        SlotSet(DIEM_DON, ticket.get(DIEM_DON)),
        SlotSet(DIEM_DEN, ticket.get(DIEM_DEN)),
        SlotSet(THOI_GIAN, ticket.get(THOI_GIAN)),
        SlotSet(LOAI_XE, ticket.get(LOAI_XE)),
        SlotSet(HO_TEN, ticket.get(HO_TEN)),
        SlotSet(REQUESTED_SLOT, SO_LUONG),
    ]


def fill_All_Form_Sua_Ve(ticket):
    return [
        SlotSet(SO_LUONG, ticket.get(SO_LUONG)),
        SlotSet(DIEN_THOAI, ticket.get(DIEN_THOAI)),
        SlotSet(DIEM_DON, ticket.get(DIEM_DON)),
        SlotSet(DIEM_DEN, ticket.get(DIEM_DEN)),
        SlotSet(THOI_GIAN, ticket.get(THOI_GIAN)),
        SlotSet(LOAI_XE, ticket.get(LOAI_XE)),
        SlotSet(HO_TEN, ticket.get(HO_TEN)),
    ]


def update_slots(tracker):
    events = []
    extractEntity = None
    entitys = tracker.latest_message.get("entities", [])

    # Không có entitys, thì kiểm tra value trong mes
    if len(entitys) == 0:
        mes = tracker.latest_message.get("text")

        # Chỉ có entity trong mes
        requested_slots = extract_entity(mes)
        if len(requested_slots) > 0:
            for s in requested_slots:
                events.append(SlotSet(s, None))

        return events

    for e in entitys:
        mes = e.get("value").strip()
        if e.get("extractor") == DIET_CLASSIFIER:
            extractEntity = e.get("entity", None)
            # if extractEntity == DIA_DIEM:
            #     events.append(SlotSet(e.get("role"), mes))
            #     continue
            events.append(SlotSet(extractEntity, e.get("value").strip()))

    return events


class reset_form(Action):

    def name(self) -> Text:
        return "action_reset_form"

    def run(
        self,
        dispatcher: CollectingDispatcher,
        tracker: Tracker,
        domain: Dict[Text, Any],
    ) -> List[Dict[Text, Any]]:
        return [ActiveLoop(None), AllSlotsReset(), Restarted()]


# MARK: ROUTE ACTION
class route_action(Action):

    def name(self) -> Text:
        return "action_route_action"

    def run(
        self,
        dispatcher: CollectingDispatcher,
        tracker: Tracker,
        domain: Dict[Text, Any],
    ) -> List[Dict[Text, Any]]:

        intent = tracker.latest_message.get("intent").get("name")
        status_form = tracker.get_slot(STATUS_FORM)
        flag_form = tracker.get_slot(FLAG_FORM)
        confirm_form = tracker.get_slot(CONFIRM_FORM)

        events = []

        if intent == HUY:
            # TODO: luồng hủy vé
            # if not flag_form:
            #     events.append(SlotSet(FLAG_FORM, FORM_HUY_VE))
            #     events.append(FollowupAction("action_tra_cuu_ve"))

            if status_form == IN_PROCESS:
                dispatcher.utter_message(f"Anh chị chắc chắn muốn hủy ạ")
                events.append(SlotSet(STATUS_FORM, CANCEL_PROCESS))
                events.append(ActiveLoop(None))

            if status_form == POST_PROCESS:
                dispatcher.utter_message(
                    f"Đã hủy thành công. Anh chị muốn em hỗ trợ gì không ạ"
                )
                events.append(Restarted())

            if status_form == CANCEL_PROCESS:
                events.append(SlotSet(STATUS_FORM, IN_PROCESS))
                events.append(FollowupAction(flag_form))

            return events

        if intent == DONG_Y:
            if status_form == CANCEL_PROCESS:
                dispatcher.utter_message(
                    f"Đã hủy thành công. Anh chị muốn em hỗ trợ gì không ạ"
                )
                events.append(Restarted())

            if status_form == POST_PROCESS:
                events.append(FollowupAction(f"action_submit_{flag_form}"))

            if len(events) == 0:
                events.append(Restarted())

            return events

        if intent == TU_CHOI:
            if status_form == CANCEL_PROCESS or status_form == MODIFI_PROCESS:
                events.append(FollowupAction(flag_form))

            if status_form == POST_PROCESS:
                dispatcher.utter_message(text=f"Anh chị muốn sửa thêm thông tin gì ạ")
                events.append(SlotSet(STATUS_FORM, MODIFI_PROCESS))

            # if status_form == MODIFI_PROCESS:
            #     events.append(FollowupAction(flag_form))

            return events

        if intent == SUA_THONG_TIN:
            # TODO: luồng sửa riêng
            #     if not flag_form:
            #         events.append(SlotSet(FLAG_FORM, FORM_SUA_VE))
            #         events.append(FollowupAction("action_tra_cuu_ve"))

            # if flag_form == FORM_SUA_VE:
            if flag_form:
                events.append(FollowupAction(f"action_sua_thong_tin_{flag_form}"))

            return events

        if intent == CUNG_CAP_THONG_TIN:
            if not flag_form:
                # events.append(SlotSet(FLAG_FORM, FORM_SUA_VE))
                # events.append(FollowupAction("action_tra_cuu_ve"))
                # Kiểm tra entity trong intent để xác định form
                events.append(FollowupAction(FORM_DAT_VE))

            if flag_form and confirm_form:
                return [FollowupAction(f"action_sua_thong_tin_{flag_form}")]

            if flag_form and intent != DAT_VE:
                events.append(FollowupAction("action_tra_cuu_ve"))

            return events

        if intent == DAT_VE and not flag_form:
            events.append(FollowupAction(FORM_DAT_VE))
            return events

        print(f"route: {events}")
        return events


# MARK: CHÀO HỎI
class chao_hoi(Action):

    def name(self) -> Text:
        return "action_chao_hoi"

    def run(
        self,
        dispatcher: CollectingDispatcher,
        tracker: Tracker,
        domain: Dict[Text, Any],
    ) -> List[Dict[Text, Any]]:

        sender_id = tracker.sender_id.strip().title() # sender có dạng 'tên nhà xe|số điện thoại khách hàng'
        info_sender = split_string(sender_id)
        if len(info_sender) == 2:
            ten_nha_xe, _ = info_sender
            if ten_nha_xe.strip() != "":
                dispatcher.utter_message(
                    text=f"Nhà xe {ten_nha_xe} xin chào quý khách, em giúp gì cho anh chị ạ"
                )
            else:
                dispatcher.utter_message(
                    text="Xin chào quý khách, em giúp gì cho anh chị ạ?"
                )

        return []

def get_state(tracker):
    state = "[State]:{ "
    if (tracker.get_slot(REQUESTED_SLOT) is not None):
        print(tracker.get_slot(REQUESTED_SLOT), 123)
        state += f"{REQUESTED_SLOT}: {tracker.get_slot(REQUESTED_SLOT)}"
    
    state+= "}"
    return state

# MARK: FORM ĐẶT XE
class ValidateFormDatXe(FormValidationAction):

    def name(self) -> Text:
        return "validate_form_dat_ve"

    # thêm valid địa điểm
    # def valid_diem_don:
    # def valid_diem_den:
    def run(
        self,
        dispatcher: CollectingDispatcher,
        tracker: Tracker,
        domain: DomainDict,
    ) -> List[Dict[Text, Any]]:

        text = tracker.latest_message.get("text")
        print("User text:", text)
        intent = tracker.latest_message.get("intent").get("name")
        
        # Kiểm tra intent
        if intent == HUY:
            return []
        if intent == DONG_Y:
            sender_id = tracker.sender_id.strip().title() # sender có dạng 'tên nhà xe|số điện thoại khách hàng'
            info_sender = split_string(sender_id)
            if len(info_sender) == 2:
                _, phone_num = info_sender
                return[SlotSet(DIEN_THOAI, phone_num)]
        
        event = [
            SlotSet(FLAG_FORM, "form_dat_ve"),
            SlotSet(CONFIRM_FORM, False),
            SlotSet(STATUS_FORM, IN_PROCESS),
        ]

        entities = tracker.latest_message.get("entities", [])
        last_req_slot = tracker.get_slot(REQUESTED_SLOT)

        # Hỏi lại khi không có entities
        if len(entities) == 0:
            if last_req_slot:
                event.append(SlotSet(last_req_slot, None))
            return event

        # phone = ""
        for entiti in entities:
            entity_name = entiti.get("entity")
            value = entiti.get("value")

            if entity_name == DIA_DIEM:
                value, role = valid_dia_diem(value, entiti, text)
                print(role)
                if value is None:
                    # dispatcher.utter_message(text=f"không có địa điểm {value} trong hệ thống")
                    pass
                if role == "undetected":
                    if last_req_slot == DIEM_DON or last_req_slot == DIEM_DEN:
                        event.append(SlotSet(last_req_slot, value))
                    else: 
                        continue
                else:
                    event.append(SlotSet(role, value))
            elif entity_name == THOI_GIAN:
                if valid_thoi_gian(value, entiti) is None:
                    dispatcher.utter_message(text=f"Thời gian đặt không hợp lệ")
                event.append(SlotSet(THOI_GIAN, valid_thoi_gian(value, entiti)))
            elif entity_name == DIEN_THOAI:
                if valid_dien_thoai(value, entiti) is None:
                    dispatcher.utter_message(text=f"Số điện thoại không hợp lệ")
                event.append(SlotSet(DIEN_THOAI, valid_dien_thoai(value, entiti)))
            elif entity_name == SO_LUONG:
                if valid_so_luong(value, entiti) is None:
                    dispatcher.utter_message(text=f"Không xác định được số vé đặt")
                event.append(SlotSet(SO_LUONG, valid_so_luong(value, entiti)))
            elif entity_name == HO_TEN:
                if valid_ho_ten(value, entiti) is None:
                    dispatcher.utter_message(text=f"Không xác định được tên người")
                event.append(SlotSet(HO_TEN, valid_ho_ten(value, entiti)))
            # TODO: Có xử lý loại xe trong form đặt xe:
            # elif entity_name == LOAI_XE:
            #     if valid_loai_xe(value, entiti) is None:
            #         dispatcher.utter_message(text=f"Không có loại xe {value}")
            #     event.append(SlotSet(LOAI_XE, valid_loai_xe(value, entiti)))

            # if entiti.get("extractor") == DIET_CLASSIFIER:
            #     diet_conf = entiti.get("confidence_entity")
            #     dispatcher.utter_message(text=f"Không hiểu {entiti.get('entity')} là {entiti.get('value')}")
            #     # TODO: làm phần tự hiểu
            #     return event
            # elif entiti.get("extractor") == REGEX_ENTITY_EXTRACTOR:

            #     entity_name = entiti.get("entity", "")
            #     value = entiti.get("value", "").strip()

            #     if entity_name == DIA_DIEM:
            #         entity_role = entiti.get("role")
            #         if entity_role == "undetected":
            #             if last_req_slot is not None:
            #                 event.append(SlotSet(last_req_slot,value))
            #             else:
            #                 event.append(SlotSet(DIEM_DON,value))
            #         else:
            #             event.append(SlotSet(entity_role,value))
            #     elif entity_name == DIEN_THOAI:
            #         phone += value
            #         event.append(SlotSet(entity_name, phone))
            #     # Hay nhận nhầm số lượng, số điện thoại thành thời gian
            #     elif entity_name == THOI_GIAN and last_req_slot == THOI_GIAN:
            #         event.append(SlotSet(entity_name, value))
            #     elif (
            #         entity_name == THOI_GIAN
            #         and last_req_slot == DIEN_THOAI
            #         and len(phone) < 10
            #     ):
            #         phone += value
            #         event.append(SlotSet(DIEN_THOAI, phone))
            #     else:
            #         event.append(SlotSet(entity_name, value))

            # # Kiểm tra số điện thoại, nếu chưa đủ thì chờ
            # if len(phone) < 10 and last_req_slot == DIEN_THOAI:
            #     return [SlotSet(DIEN_THOAI, phone)]
        
        return event

# MARK: SUBMIT DAT VE
class submit_dat_ve(Action):

    def name(self) -> Text:
        return "action_submit_form_dat_ve"

    def run(
        self,
        dispatcher: CollectingDispatcher,
        tracker: Tracker,
        domain: Dict[Text, Any],
    ) -> List[Dict[Text, Any]]:

        events = []
        confirm = tracker.get_slot(CONFIRM_FORM)
        flag_form = tracker.get_slot(FLAG_FORM)
        if confirm and flag_form == "form_dat_ve":
            dispatcher.utter_message(text=(f"Đã đặt xe thành công. Anh chị có muốn hỗ trợ gì không ạ"))
            events = [Restarted()]

        return events

# MARK: CONFIRM DAT VE
class xac_nhan_form_dat_ve(Action):

    def name(self) -> Text:
        return "action_xac_nhan_form_dat_ve"

    def run(
        self,
        dispatcher: CollectingDispatcher,
        tracker: Tracker,
        domain: Dict[Text, Any],
    ) -> List[Dict[Text, Any]]:

        event = [
            FollowupAction("action_listen"),
            SlotSet(CONFIRM_FORM, True),
            SlotSet(STATUS_FORM, POST_PROCESS),
        ]

        diem_don = tracker.get_slot("diem_don")
        diem_den = tracker.get_slot("diem_den")
        thoi_gian = tracker.get_slot("thoi_gian")
        loai_xe = tracker.get_slot("loai_xe")
        so_luong = tracker.get_slot("so_luong")
        ho_ten = tracker.get_slot("ho_ten")
        dien_thoai = tracker.get_slot("dien_thoai")

        dispatcher.utter_message(
            text=(
                f"Em xác nhận thông tin đặt vé của anh chị:"
                f"Đón tại: {diem_don}"
                f"Đến: {diem_den}"
                f"Giờ: {thoi_gian}"
                f"Loại xe: {loai_xe}"
                f"Số lượng: {so_luong}"
                f"Họ tên: {ho_ten}"
                f"Điện thoại: {dien_thoai}"
            )
        )

        return event

# MARK: SUA FORM DAT VE
class sua_thong_tin_form_dat_ve(Action):

    def name(self) -> Text:
        return "action_sua_thong_tin_form_dat_ve"

    def run(
        self,
        dispatcher: CollectingDispatcher,
        tracker: Tracker,
        domain: Dict[Text, Any],
    ) -> List[Dict[Text, Any]]:

        events = []
        events += update_slots(tracker)
        if len(events) == 0:
            return [FollowupAction("action_listen")]
        else:
            events.append(FollowupAction("form_dat_ve"))

        return events


# MARK: TRA CỨU VÉ
class tra_cuu_ve(Action):

    def name(self) -> Text:
        return "action_tra_cuu_ve"

    def run(
        self,
        dispatcher: CollectingDispatcher,
        tracker: Tracker,
        domain: Dict[Text, Any],
    ) -> List[Dict[Text, Any]]:

        events = [FollowupAction("action_listen"), SlotSet(STATUS_FORM, IN_PROCESS)]

        ten_nha_xe = tracker.sender_id
        value = tracker.latest_message.get("text")
        entities = tracker.latest_message.get("entities", [])
        flag_form = tracker.get_slot(FLAG_FORM)
        list_tickets = tracker.get_slot(LIST_TICKETS)
        phone = tracker.get_slot(DIEN_THOAI)
        time = tracker.get_slot(THOI_GIAN)
        name = tracker.get_slot(HO_TEN)
        diem_don = tracker.get_slot(DIEM_DON)
        diem_den = tracker.get_slot(DIEM_DEN)
        so_luong = tracker.get_slot(SO_LUONG)
        last_requested_slot = tracker.get_slot(REQUESTED_SLOT)

        ask_so_luong = False

        if not last_requested_slot:
            last_requested_slot = DIEN_THOAI

        for entiti in entities:
            if entiti.get("extractor") != DIET_CLASSIFIER:
                continue

            entity_name = entiti.get("entity", "")
            value = entiti.get("value", "").strip()

            if entity_name == DIEN_THOAI:
                phone = value
                list_tickets = get_list_from_phone(phone)
                last_requested_slot = THOI_GIAN
                # Kiểm tra list, nếu không có thì thông báo, có 1 thì xác nhận
                events += [
                    SlotSet(LIST_TICKETS, list_tickets),
                    SlotSet(REQUESTED_SLOT, THOI_GIAN),
                    SlotSet(DIEN_THOAI, phone),
                ]

            elif entity_name == THOI_GIAN and last_requested_slot == THOI_GIAN:
                time = value
                list_tickets = get_list_dynamic(list_tickets, THOI_GIAN, time)
                last_requested_slot = HO_TEN
                events += [
                    SlotSet(LIST_TICKETS, list_tickets),
                    SlotSet(REQUESTED_SLOT, HO_TEN),
                    SlotSet(THOI_GIAN, time),
                ]

            elif entity_name == HO_TEN:
                name = value
                list_tickets = get_list_dynamic(list_tickets, HO_TEN, name)
                last_requested_slot = DIEM_DON
                events += [
                    SlotSet(LIST_TICKETS, list_tickets),
                    SlotSet(REQUESTED_SLOT, DIEM_DON),
                    SlotSet(HO_TEN, name),
                ]

            elif entity_name == DIA_DIEM and entiti.get("role") == DIEM_DON:
                diem_don = value
                list_tickets = get_list_dynamic(list_tickets, DIEM_DON, diem_don)
                last_requested_slot = DIEM_DEN
                events += [
                    SlotSet(LIST_TICKETS, list_tickets),
                    SlotSet(REQUESTED_SLOT, DIEM_DEN),
                    SlotSet(DIEM_DON, diem_don),
                ]

            elif entity_name == DIA_DIEM and entiti.get("role") == DIEM_DEN:
                diem_den = value
                list_tickets = get_list_dynamic(list_tickets, DIEM_DEN, diem_den)
                last_requested_slot = SO_LUONG
                events += [
                    SlotSet(LIST_TICKETS, list_tickets),
                    SlotSet(REQUESTED_SLOT, SO_LUONG),
                    SlotSet(DIEM_DEN, diem_den),
                ]
            elif entity_name == SO_LUONG:
                so_luong = value
                last_requested_slot = None
                events += [
                    SlotSet(REQUESTED_SLOT, None),
                    SlotSet(SO_LUONG, so_luong),
                ]

            elif last_requested_slot == SO_LUONG and value != "":
                so_luong = value
                last_requested_slot = None
                events += [
                    SlotSet(REQUESTED_SLOT, None),
                    SlotSet(SO_LUONG, so_luong),
                ]

        if list_tickets:
            count = len(list_tickets)
            if count == 0:
                dispatcher.utter_message(text=f"Em không tìm thấy vé nào có số {phone}")
                return [Restarted()]

            if count == 1:
                if list_tickets[0].get(SO_LUONG) == 1:
                    events += fill_All_Form_Sua_Ve(list_tickets[0])
                    events += [
                        FollowupAction(f"action_xac_nhan_{flag_form}"),
                        SlotSet(STATUS_FORM, POST_PROCESS),
                    ]
                else:
                    ask_so_luong = True
            else:
                if so_luong:
                    # Chưa xử lý đúng
                    events += fill_All_Form_Sua_Ve(list_tickets[0])
                    events += [
                        FollowupAction(f"action_sua_thong_tin_{flag_form}"),
                        SlotSet(STATUS_FORM, POST_PROCESS),
                    ]

        if not ask_so_luong and last_requested_slot:
            dispatcher.utter_message(
                template=f"utter_ask_{flag_form}_{last_requested_slot}"
            )
            return events

        if not so_luong:
            dispatcher.utter_message(template=f"utter_ask_{flag_form}_so_luong")
            events += [SlotSet(REQUESTED_SLOT, SO_LUONG)]
            return events
        else:
            events += [
                FollowupAction(f"action_xac_nhan_{flag_form}"),
                SlotSet(STATUS_FORM, POST_PROCESS),
            ]

        events += [SlotSet(STATUS_FORM, POST_PROCESS), SlotSet(CONFIRM_FORM, True)]

        return events


# MARK: SỬA VÉ
class sua_thong_tin_form_sua_ve(Action):

    def name(self) -> Text:
        return "action_sua_thong_tin_form_sua_ve"

    def run(
        self,
        dispatcher: CollectingDispatcher,
        tracker: Tracker,
        domain: Dict[Text, Any],
    ) -> List[Dict[Text, Any]]:
        events = []
        events = update_slots(tracker)
        if len(events) == 0:
            events.append(FollowupAction("action_listen"))
        else:
            events.append(FollowupAction("form_sua_ve"))
        return events


class xac_nhan_sua_ve(Action):
    def name(self) -> Text:
        return "action_xac_nhan_form_sua_ve"

    def run(
        self,
        dispatcher: CollectingDispatcher,
        tracker: Tracker,
        domain: Dict[Text, Any],
    ) -> List[Dict[Text, Any]]:

        status_form = tracker.get_slot(STATUS_FORM)
        if status_form == IN_PROCESS:
            dispatcher.utter_message(text=("Anh chị muốn sửa thông tin gì ạ"))
            return [FollowupAction("action_listen")]

        list_ticket = tracker.get_slot(LIST_TICKETS)
        diem_don = tracker.get_slot(DIEM_DON)
        diem_den = tracker.get_slot(DIEM_DEN)
        thoi_gian = tracker.get_slot(THOI_GIAN)
        dien_thoai = tracker.get_slot(DIEN_THOAI)
        ho_ten = tracker.get_slot(HO_TEN)
        loai_xe = tracker.get_slot(LOAI_XE)
        so_luong = tracker.get_slot(SO_LUONG)

        dispatcher.utter_message(
            text=(
                f"Em xác nhận thông tin của anh chị:"
                f"Đón tại: {diem_don}"
                f"Đến: {diem_den}"
                f"Giờ: {thoi_gian}"
                f"Loại xe: {loai_xe}"
                f"Số lượng: {so_luong}"
                f"Họ tên: {ho_ten}"
                f"Điện thoại: {dien_thoai}"
            )
        )
        dispatcher.utter_message(text=f"Thông tin vé đã đúng chưa ạ")

        return [SlotSet(CONFIRM_FORM, True), FollowupAction("action_listen")]


class submit_sua_ve(Action):
    def name(self) -> Text:
        return "action_submit_form_sua_ve"

    def run(
        self,
        dispatcher: CollectingDispatcher,
        tracker: Tracker,
        domain: Dict[Text, Any],
    ) -> List[Dict[Text, Any]]:

        event = [AllSlotsReset(), Restarted()]
        dispatcher.utter_message(text=f"Sửa vé thành công, Anh chị cần giúp gì không ạ")
        return event


# MARK: HỦY VÉ
class ValidateFormHuyVe(FormValidationAction):

    def name(self) -> Text:
        return "validate_form_huy_ve"

    def run(self, dispatcher, tracker, domain):
        flag_form = tracker.get_slot(FLAG_FORM)
        if flag_form != FORM_HUY_VE:
            return []

        events = [SlotSet(FLAG_FORM, "form_huy_ve"), SlotSet(CONFIRM_FORM, False)]
        last_req_slot = tracker.get_slot(REQUESTED_SLOT)
        ten_nha_xe = tracker.sender_id
        entities = tracker.latest_message.get("entities", [])

        if len(entities) == 0:
            if last_req_slot:
                events.append(SlotSet(last_req_slot, None))
            return events

        ticket_list = tracker.get_slot("list_tickets")
        value = ""

        for entiti in entities:
            if entiti.get("extractor") != DIET_CLASSIFIER:
                continue

            entity_name = entiti.get("entity")
            value = entiti.get("value", "").strip()

            if entity_name == DIEN_THOAI:
                ticket_list = get_list_from_phone_at_server(ten_nha_xe, value)
                events.append(SlotSet(entity_name, value))

            elif entity_name == THOI_GIAN and last_req_slot == THOI_GIAN:
                # Do nhận nhầm giữa thời gian và số lượng
                ticket_list = get_list_dynamic(ticket_list, THOI_GIAN, value)
                events.append(SlotSet(entity_name, value))

            elif entity_name == HO_TEN:
                ticket_list = get_list_dynamic(ticket_list, HO_TEN, value)
                events.append(SlotSet(entity_name, value))

            elif entity_name == DIA_DIEM and entiti.get("role") == "don":
                ticket_list = get_list_dynamic(ticket_list, DIEM_DON, value)
                events.append(SlotSet(entity_name, value))

            elif entity_name == DIA_DIEM and entiti.get("role") == "den":
                ticket_list = get_list_dynamic(ticket_list, DIEM_DEN, value)
                events.append(SlotSet(entity_name, value))

            elif entity_name == SO_LUONG:
                events.append(SlotSet(entity_name, value))

        if ticket_list and len(ticket_list) > 0:
            events.append(SlotSet(LIST_TICKETS, ticket_list))
            events.append(SlotSet(HAS_LIST, True))

        count_booking = len(ticket_list)
        if count_booking == 0:
            events.append(ActiveLoop(None))
            dispatcher.utter_message(text=f"Anh chị không có vé nào")
        elif count_booking == 1:
            if ticket_list[0].get(SO_LUONG) == 1:
                events.append(ActiveLoop(None))
                events.append(FollowupAction("action_xac_nhan_form_huy_ve"))
            elif ticket_list[0].get(SO_LUONG) > 1 and not tracker.get_slot(
                CONFIRM_FORM
            ):
                events.append(SlotSet(REQUESTED_SLOT, SO_LUONG))

        if (last_req_slot == SO_LUONG and value != "") or tracker.get_slot(
            CONFIRM_FORM
        ):
            events.append(ActiveLoop(None))
            events.append(FollowupAction("action_xac_nhan_form_huy_ve"))

        return events


class xac_nhan_huy_ve(Action):

    def name(self) -> Text:
        return "action_xac_nhan_form_huy_ve"

    def run(
        self,
        dispatcher: CollectingDispatcher,
        tracker: Tracker,
        domain: Dict[Text, Any],
    ) -> List[Dict[Text, Any]]:

        list_tickets = tracker.get_slot(LIST_TICKETS)
        so_luong = tracker.get_slot(SO_LUONG)
        ask_so_luong = True
        events = [SlotSet(CONFIRM_FORM, True), FollowupAction("action_listen")]

        if list_tickets:
            if len(list_tickets) == 1:
                if list_tickets[0].get(SO_LUONG) == 1:
                    dispatcher.utter_message(
                        text=
                        f"Em xác nhận thông tin hủy vé của anh chị:"
                        f"Điểm đón: {list_tickets[0].get('diem_don')}"
                        f"Điểm đến: {list_tickets[0].get('diem_den')}"
                        f"Thời gian: {list_tickets[0].get('thoi_gian')}"
                        f"Họ tên: {list_tickets[0].get('ho_ten')}"
                    )
                    ask_so_luong = False

        if ask_so_luong:
            dispatcher.utter_message(text=f"Em xác nhận anh chị muốn hủy {so_luong} vé")

        return events


class submit_huy_ve(Action):

    def name(self) -> Text:
        return "action_submit_form_huy_ve"

    def run(
        self,
        dispatcher: CollectingDispatcher,
        tracker: Tracker,
        domain: Dict[Text, Any],
    ) -> List[Dict[Text, Any]]:

        events = [Restarted()]

        so_luong = int(tracker.get_slot(SO_LUONG))
        list_tickets = tracker.get_slot("list_tickets")

        if len(list_tickets) == 1:
            if list_tickets[0].get(SO_LUONG) == 1:
                text = "finished|Đã hủy vé thành công!"
            else:
                if so_luong > list_tickets[0].get(SO_LUONG):
                    text = f"Số lượng vé không đủ"
                    events = [
                        ActiveLoop("form_huy_ve"),
                        SlotSet(REQUESTED_SLOT, SO_LUONG),
                    ]
                else:
                    text = f"Đã hủy {so_luong} vé thành công!"
        else:
            # Trùng toàn bộ
            count = 0
            for ticket in list_tickets:
                count += int(ticket.get(SO_LUONG))

            if so_luong > count:
                text = f"Số lượng vé không đủ"
                events = [ActiveLoop("form_huy_ve"), SlotSet(REQUESTED_SLOT, SO_LUONG)]
            else:
                text = f"Đã hủy {so_luong} vé thành công!"

        dispatcher.utter_message(text=(text))

        return events
