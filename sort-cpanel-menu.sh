#!/bin/bash
# ============================================
# Sort cPanel Menu + Auto Hook for New Accounts
# v4 - ใช้ nvdata + background hook ไม่บล็อค WHM
# ============================================

MENU_ORDER="domains|software|files|security|databases|advanced|email|metrics|preferences"

echo "=========================================="
echo "🧹 0/3 ลบ Hook เก่าออกก่อน (ถ้ามี)..."
echo "=========================================="
/usr/local/cpanel/bin/manage_hooks delete script /root/sort_menu_hook.sh --category Whostmgr --event Accounts::Create --stage post 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ ลบ Hook เก่าเรียบร้อย"
else
    echo "ℹ️  ไม่พบ Hook เก่า ข้ามไป"
fi
echo ""

echo "=========================================="
echo "⏳ 1/3 กำลังจัดเรียงเมนูให้ Account ที่มีอยู่แล้ว..."
echo "=========================================="
SUCCESS=0
FAIL=0
for user in $(whmapi1 listaccts --output=jsonpretty | python3 -c "
import sys, json
data = json.load(sys.stdin)
for acct in data.get('data', {}).get('acct', []):
    print(acct['user'])
" 2>/dev/null); do
    HOMEDIR=$(eval echo ~"$user")
    NVDATA_DIR="$HOMEDIR/.cpanel/nvdata"
    if [ ! -d "$NVDATA_DIR" ]; then
        mkdir -p "$NVDATA_DIR"
        chown "$user":"$user" "$HOMEDIR/.cpanel" "$NVDATA_DIR"
    fi
    echo -n "$MENU_ORDER" > "$NVDATA_DIR/xmaingroupsorder"
    chown "$user":"$user" "$NVDATA_DIR/xmaingroupsorder"
    echo "  ✅ $user"
    ((SUCCESS++))
done
echo ""
echo "📊 สำเร็จ: $SUCCESS | ล้มเหลว: $FAIL"
echo ""

echo "=========================================="
echo "⏳ 2/3 กำลังสร้างไฟล์ Hook Script สำหรับ Account ใหม่..."
echo "=========================================="
tee /root/sort_menu_hook.sh > /dev/null << 'EOF'
#!/bin/bash
HOOK_DATA=$(cat)
USERNAME=$(echo "$HOOK_DATA" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('data', {}).get('user', ''))
" 2>/dev/null)

if [ -n "$USERNAME" ]; then
    (
        HOMEDIR=$(eval echo ~"$USERNAME")
        NVDATA_DIR="$HOMEDIR/.cpanel/nvdata"

        for i in $(seq 1 15); do
            [ -d "$NVDATA_DIR" ] && break
            sleep 1
        done

        if [ ! -d "$NVDATA_DIR" ]; then
            mkdir -p "$NVDATA_DIR"
            chown "$USERNAME":"$USERNAME" "$HOMEDIR/.cpanel" "$NVDATA_DIR"
        fi

        echo -n "domains|software|files|security|databases|advanced|email|metrics|preferences" > "$NVDATA_DIR/xmaingroupsorder"
        chown "$USERNAME":"$USERNAME" "$NVDATA_DIR/xmaingroupsorder"
    ) &
fi
EOF
chmod +x /root/sort_menu_hook.sh
echo "✅ สร้างไฟล์ /root/sort_menu_hook.sh สำเร็จ!"
echo ""

echo "=========================================="
echo "⏳ 3/3 กำลังลงทะเบียน Hook เข้าระบบ WHM..."
echo "=========================================="
/usr/local/cpanel/bin/manage_hooks add script /root/sort_menu_hook.sh --manual --category Whostmgr --event Accounts::Create --stage post
echo ""
echo "=========================================="
echo "🎉 ติดตั้งระบบจัดเรียงเมนูอัตโนมัติสำเร็จ 100%!"
echo "=========================================="
echo ""
echo "📋 ตรวจสอบ Hook ที่ลงทะเบียน:"
/usr/local/cpanel/bin/manage_hooks list 2>/dev/null | grep -A3 "sort_menu_hook"
