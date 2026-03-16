# cPanel Menu Sort

จัดเรียงเมนู cPanel อัตโนมัติ + Hook สำหรับ Account ใหม่

## ลำดับเมนู

Domains → Software → Files → Security → Databases → Advanced → Email → Metrics → Preferences

## วิธีใช้

```bash
curl -sSL https://raw.githubusercontent.com/AnonymousVS/cpanel-menu-sort/refs/heads/main/sort-cpanel-menu.sh | bash
```

## สคริปต์ทำอะไรบ้าง

1. ลบ Hook เก่า (ถ้ามี)
2. จัดเรียงเมนูให้ Account ที่มีอยู่แล้วทั้งหมด
3. สร้าง Hook ให้ Account ใหม่ที่สร้างในอนาคตเรียงเมนูอัตโนมัติ

## ลบ Hook

```bash
/usr/local/cpanel/bin/manage_hooks delete script /root/sort_menu_hook.sh --category Whostmgr --event Accounts::Create --stage post
rm -f /root/sort_menu_hook.sh
```

## ความต้องการ

- WHM/cPanel
- Python 3
- Root access
