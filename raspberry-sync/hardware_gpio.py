import time
import RPi.GPIO as GPIO

BUTTON_PIN = 17

DEVICE_CONFIG = {
    "dev01": {
        "relay": 27,
        "led": 22,
        "name": "Máy in 3D Ender 3"
    },
    "dev02": {
        "relay": 5,
        "led": 23,
        "name": "Kính hiển vi"
    },
    "dev03": {
        "relay": 6,
        "led": 24,
        "name": "Trạm hàn"
    },
}

RELAY_ON = GPIO.HIGH
RELAY_OFF = GPIO.LOW

GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)

GPIO.setup(BUTTON_PIN, GPIO.IN, pull_up_down=GPIO.PUD_UP)

for device_id, cfg in DEVICE_CONFIG.items():
    GPIO.setup(cfg["relay"], GPIO.OUT)
    GPIO.setup(cfg["led"], GPIO.OUT)

    GPIO.output(cfg["relay"], RELAY_OFF)
    GPIO.output(cfg["led"], GPIO.LOW)


def is_button_pressed():
    return GPIO.input(BUTTON_PIN) == GPIO.LOW


def relay_on(device_id):
    cfg = DEVICE_CONFIG.get(device_id)

    if cfg is None:
        print(f"[GPIO] Không tìm thấy device_id: {device_id}")
        return

    GPIO.output(cfg["relay"], RELAY_ON)
    GPIO.output(cfg["led"], GPIO.HIGH)

    print(f"[GPIO] ON {device_id} - {cfg['name']}")


def relay_off(device_id):
    cfg = DEVICE_CONFIG.get(device_id)

    if cfg is None:
        print(f"[GPIO] Không tìm thấy device_id: {device_id}")
        return

    GPIO.output(cfg["relay"], RELAY_OFF)
    GPIO.output(cfg["led"], GPIO.LOW)

    print(f"[GPIO] OFF {device_id} - {cfg['name']}")


def blink_led(device_id, times=5, delay=0.2):
    cfg = DEVICE_CONFIG.get(device_id)

    if cfg is None:
        return

    pin = cfg["led"]

    for _ in range(times):
        GPIO.output(pin, GPIO.HIGH)
        time.sleep(delay)
        GPIO.output(pin, GPIO.LOW)
        time.sleep(delay)


def cleanup_gpio():
    GPIO.cleanup()