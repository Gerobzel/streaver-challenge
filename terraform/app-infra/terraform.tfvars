project     = "streaver-ch"
domain_name = "grobert-streaver.com"
alert_email = "your-email@example.com"

# Traffic routing — standard canary progression: 10/90 → 50/50 → 100/0 (promote)
image_tag_stable = "latest"
image_tag_canary = "latest"
weight_stable    = 100
weight_canary    = 0
