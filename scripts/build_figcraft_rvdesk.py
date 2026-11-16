import subprocess
import json
import os
import sys

cli_path = r"C:\Users\User\figcraft\figcraft-0.15.1-windows-x64-portable\figcraft-cli.exe"

proc = subprocess.Popen(
    [cli_path, "mcp"],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    text=True,
    bufsize=1
)

msg_id = 0

def call_mcp(method, params):
    global msg_id
    msg_id += 1
    req = {
        "jsonrpc": "2.0",
        "id": msg_id,
        "method": method,
        "params": params
    }
    proc.stdin.write(json.dumps(req) + "\n")
    proc.stdin.flush()
    resp_line = proc.stdout.readline()
    resp = json.loads(resp_line)
    if "error" in resp:
        raise Exception(f"MCP error in {method}: {resp['error']}")
    return resp.get("result", {})

# Initialize MCP
init_res = call_mcp("initialize", {
    "protocolVersion": "2024-11-05",
    "capabilities": {},
    "clientInfo": {"name": "rvsdesk-designer", "version": "1.0"}
})
proc.stdin.write(json.dumps({"jsonrpc": "2.0", "method": "notifications/initialized"}) + "\n")
proc.stdin.flush()

print("[+] Initialized FigCraft MCP")

def create_layer(type_, name, x, y, width, height, parent=None, text=None, props=None):
    params = {
        "type": type_,
        "name": name,
        "x": x,
        "y": y,
        "width": width,
        "height": height,
    }
    if parent is not None:
        params["parent"] = parent
    if text is not None:
        params["text"] = text
    if props is not None:
        params["props"] = props
    
    res = call_mcp("tools/call", {
        "name": "create_node",
        "arguments": params
    })
    content = res.get("content", [])
    node_id = None
    if content and isinstance(content, list):
        for item in content:
            if item.get("type") == "text":
                try:
                    data = json.loads(item.get("text", "{}"))
                    if "id" in data:
                        node_id = data["id"]
                except:
                    pass
    if node_id is None:
        sc = res.get("structuredContent", {})
        node_id = sc.get("id")
    print(f"  [>] Created {type_} '{name}' -> id: {node_id}")
    return node_id

# ==============================================================================
# SCREEN 1: Quick Support Home (960 x 640) - ZERO EMOJIS, ENTERPRISE CLEAN
# ==============================================================================
s1_id = create_layer("frame", "RVDesk - Quick Support Home", 0, 0, 960, 640, props={
    "fill": "#070A0F",
    "cornerRadius": 16,
    "clip": True
})

# Ambient Top Glow in Screen 1
create_layer("ellipse", "Ambient Red Glow", 330, -60, 300, 180, parent=s1_id, props={
    "fill": "#DC2626",
    "opacity": 0.10
})

# Header App Bar (x: 32, y: 24, w: 896, h: 48)
header_bg = create_layer("rectangle", "Header Bar", 32, 24, 896, 48, parent=s1_id, props={
    "fill": "#0B111A",
    "cornerRadius": 10,
    "stroke": "#1E293B",
    "strokeWeight": 1
})

# App Title & Brand
create_layer("text", "App Title", 48, 38, 90, 24, parent=s1_id, text="RVDesk", props={
    "fontSize": 18,
    "fontFamily": "Inter",
    "fontStyle": "Bold",
    "fill": "#FFFFFF"
})
create_layer("text", "Brand Subtitle", 125, 41, 160, 20, parent=s1_id, text="by RithV Services", props={
    "fontSize": 12,
    "fontFamily": "Inter",
    "fill": "#9CA3AF"
})

# Status Badge (Right of header)
status_bg = create_layer("rectangle", "Status Badge", 740, 34, 172, 28, parent=s1_id, props={
    "fill": "#064E3B",
    "cornerRadius": 999,
    "stroke": "#059669",
    "strokeWeight": 1
})
create_layer("ellipse", "Status Dot", 754, 43, 10, 10, parent=s1_id, props={
    "fill": "#10B981"
})
create_layer("text", "Status Text", 772, 40, 130, 18, parent=s1_id, text="READY FOR SUPPORT", props={
    "fontSize": 10,
    "fontFamily": "Inter",
    "fontStyle": "Bold",
    "letterSpacing": 1.0,
    "fill": "#A7F3D0"
})

# Main Support Card (Dual-Panel Container: x: 32, y: 92, w: 896, h: 480)
main_card = create_layer("rectangle", "Main Support Card", 32, 92, 896, 480, parent=s1_id, props={
    "fill": "#0F172A",
    "cornerRadius": 16,
    "stroke": "#1E293B",
    "strokeWeight": 1
})

# Panel Left: Receive Remote Assistance (Your Device)
create_layer("text", "Left Title", 64, 124, 360, 30, parent=s1_id, text="Allow Remote Support", props={
    "fontSize": 20,
    "fontFamily": "Inter",
    "fontStyle": "Bold",
    "fill": "#FFFFFF"
})
create_layer("text", "Left Desc", 64, 158, 360, 36, parent=s1_id, text="Share this ID and one-time password with your RithV Services technician to begin repair.", props={
    "fontSize": 12,
    "fontFamily": "Inter",
    "fill": "#9CA3AF"
})

# ID Card Box
create_layer("rectangle", "ID Box", 64, 210, 370, 96, parent=s1_id, props={
    "fill": "#020617",
    "cornerRadius": 12,
    "stroke": "#DC2626",
    "strokeWeight": 1
})
create_layer("text", "ID Label", 84, 224, 120, 18, parent=s1_id, text="YOUR DEVICE ID", props={
    "fontSize": 10,
    "fontFamily": "Inter",
    "fontStyle": "Bold",
    "letterSpacing": 1.5,
    "fill": "#F87171"
})
create_layer("text", "ID Digits", 84, 246, 240, 44, parent=s1_id, text="948 201 582", props={
    "fontSize": 32,
    "fontFamily": "Inter",
    "fontStyle": "Bold",
    "fill": "#FFFFFF"
})

# Professional COPY Button (clean vector badge, NO EMOJI)
create_layer("rectangle", "Copy Btn Box", 340, 242, 74, 34, parent=s1_id, props={
    "fill": "#1E293B",
    "cornerRadius": 6,
    "stroke": "#334155",
    "strokeWeight": 1
})
create_layer("text", "Copy Btn Text", 356, 252, 44, 16, parent=s1_id, text="COPY", props={
    "fontSize": 11,
    "fontFamily": "Inter",
    "fontStyle": "Bold",
    "letterSpacing": 1.2,
    "fill": "#F87171"
})

# Password Card Box
create_layer("rectangle", "Password Box", 64, 326, 370, 72, parent=s1_id, props={
    "fill": "#020617",
    "cornerRadius": 12,
    "stroke": "#1E293B",
    "strokeWeight": 1
})
create_layer("text", "Pass Label", 84, 338, 160, 18, parent=s1_id, text="ONE-TIME PASSCODE", props={
    "fontSize": 10,
    "fontFamily": "Inter",
    "fontStyle": "Bold",
    "letterSpacing": 1.2,
    "fill": "#9CA3AF"
})
create_layer("text", "Pass Digits", 84, 360, 200, 28, parent=s1_id, text="rvs • 8492", props={
    "fontSize": 18,
    "fontFamily": "Inter",
    "fontStyle": "Bold",
    "fill": "#FFFFFF"
})

# Professional SHOW Toggle Button (NO EMOJI)
create_layer("rectangle", "Show Btn Box", 340, 344, 74, 34, parent=s1_id, props={
    "fill": "#1E293B",
    "cornerRadius": 6,
    "stroke": "#334155",
    "strokeWeight": 1
})
create_layer("text", "Show Btn Text", 356, 354, 44, 16, parent=s1_id, text="SHOW", props={
    "fontSize": 10,
    "fontFamily": "Inter",
    "fontStyle": "Bold",
    "letterSpacing": 1.0,
    "fill": "#94A3B8"
})

# Center Divider Line
create_layer("rectangle", "Center Divider", 479, 130, 2, 400, parent=s1_id, props={
    "fill": "#1E293B"
})

# Panel Right: Connect to Remote Desktop (Technician Controller)
create_layer("text", "Right Title", 520, 124, 360, 30, parent=s1_id, text="Control Remote Desktop", props={
    "fontSize": 20,
    "fontFamily": "Inter",
    "fontStyle": "Bold",
    "fill": "#FFFFFF"
})
create_layer("text", "Right Desc", 520, 158, 360, 36, parent=s1_id, text="Enter the customer or target partner ID to initiate direct encrypted remote session.", props={
    "fontSize": 12,
    "fontFamily": "Inter",
    "fill": "#9CA3AF"
})

# Remote ID Input Box
create_layer("rectangle", "Input Box", 520, 210, 370, 60, parent=s1_id, props={
    "fill": "#020617",
    "cornerRadius": 12,
    "stroke": "#334155",
    "strokeWeight": 1
})
create_layer("text", "Input Placeholder", 540, 228, 300, 26, parent=s1_id, text="Partner ID: 000 000 000", props={
    "fontSize": 16,
    "fontFamily": "Inter",
    "fill": "#64748B"
})

# Connect Button (Crimson Red #DC2626 - ZERO EMOJI)
create_layer("rectangle", "Connect CTA Button", 520, 290, 370, 56, parent=s1_id, props={
    "fill": "#DC2626",
    "cornerRadius": 12,
    "stroke": "#EF4444",
    "strokeWeight": 1
})
create_layer("text", "Connect Btn Text", 635, 308, 150, 24, parent=s1_id, text="Connect to Partner", props={
    "fontSize": 15,
    "fontFamily": "Inter",
    "fontStyle": "Bold",
    "letterSpacing": 0.5,
    "fill": "#FFFFFF"
})

# Security Info Notice in Right Panel (ZERO EMOJI)
create_layer("rectangle", "Notice Box", 520, 370, 370, 80, parent=s1_id, props={
    "fill": "#0B111A",
    "cornerRadius": 10,
    "stroke": "#1E293B",
    "strokeWeight": 1
})
create_layer("rectangle", "Notice Accent Strip", 520, 370, 4, 80, parent=s1_id, props={
    "fill": "#DC2626",
    "cornerRadius": 2
})
create_layer("text", "Notice Header", 538, 384, 180, 16, parent=s1_id, text="SECURITY NOTICE", props={
    "fontSize": 10,
    "fontFamily": "Inter",
    "fontStyle": "Bold",
    "letterSpacing": 1.2,
    "fill": "#F87171"
})
create_layer("text", "Notice Text", 538, 404, 340, 36, parent=s1_id, text="Outgoing controller sessions require RVS authorization passkey. Unverified sessions are blocked at gateway.", props={
    "fontSize": 11,
    "fontFamily": "Inter",
    "fill": "#94A3B8"
})

# Footer Bar
create_layer("text", "Footer Copyright", 260, 594, 440, 20, parent=s1_id, text="RVDesk Portable Client • Powered by RithV Services • End-to-End Encrypted", props={
    "fontSize": 11,
    "fontFamily": "Inter",
    "fill": "#64748B"
})

print("[+] Completed Screen 1: Quick Support Home (Clean, No Emojis)")

# ==============================================================================
# SCREEN 2: Controller Secret Authentication Modal (480 x 340) - ZERO EMOJIS
# ==============================================================================
s2_id = create_layer("frame", "RVDesk - Controller Auth Modal", 1020, 0, 480, 340, props={
    "fill": "#070A0F",
    "cornerRadius": 16,
    "clip": True
})

modal_card = create_layer("rectangle", "Modal Card", 20, 20, 440, 300, parent=s2_id, props={
    "fill": "#0F172A",
    "cornerRadius": 16,
    "stroke": "#DC2626",
    "strokeWeight": 1
})

# Badge: Clean Text Capsule
create_layer("rectangle", "Modal Badge Box", 44, 44, 180, 24, parent=s2_id, props={
    "fill": "#1E293B",
    "cornerRadius": 4,
    "stroke": "#334155",
    "strokeWeight": 1
})
create_layer("text", "Modal Badge", 54, 49, 160, 16, parent=s2_id, text="CONTROLLER GATEWAY", props={
    "fontSize": 9,
    "fontFamily": "Inter",
    "fontStyle": "Bold",
    "letterSpacing": 1.2,
    "fill": "#F87171"
})

create_layer("text", "Modal Title", 44, 80, 380, 28, parent=s2_id, text="Server Authorization Required", props={
    "fontSize": 18,
    "fontFamily": "Inter",
    "fontStyle": "Bold",
    "fill": "#FFFFFF"
})

create_layer("text", "Modal Desc", 44, 114, 380, 36, parent=s2_id, text="This controller is verified against rithvservices.my.id. Enter the administrator secret password to proceed.", props={
    "fontSize": 12,
    "fontFamily": "Inter",
    "fill": "#9CA3AF"
})

# Password Input
create_layer("rectangle", "Modal Pass Input", 44, 160, 392, 50, parent=s2_id, props={
    "fill": "#020617",
    "cornerRadius": 10,
    "stroke": "#334155",
    "strokeWeight": 1
})
create_layer("text", "Modal Pass Text", 60, 175, 260, 24, parent=s2_id, text="••••••••••••••••", props={
    "fontSize": 16,
    "fontFamily": "Inter",
    "fill": "#FFFFFF"
})

# Show toggle button in modal
create_layer("rectangle", "Modal Toggle Box", 364, 168, 60, 34, parent=s2_id, props={
    "fill": "#1E293B",
    "cornerRadius": 6
})
create_layer("text", "Modal Toggle Text", 376, 177, 36, 16, parent=s2_id, text="SHOW", props={
    "fontSize": 9,
    "fontFamily": "Inter",
    "fontStyle": "Bold",
    "letterSpacing": 0.8,
    "fill": "#94A3B8"
})

# Buttons Row
create_layer("rectangle", "Cancel Btn", 44, 230, 130, 46, parent=s2_id, props={
    "fill": "#1E293B",
    "cornerRadius": 10,
    "stroke": "#334155",
    "strokeWeight": 1
})
create_layer("text", "Cancel Text", 86, 244, 60, 20, parent=s2_id, text="Cancel", props={
    "fontSize": 14,
    "fontFamily": "Inter",
    "fill": "#9CA3AF"
})

create_layer("rectangle", "Auth CTA Btn", 188, 230, 248, 46, parent=s2_id, props={
    "fill": "#DC2626",
    "cornerRadius": 10,
    "stroke": "#EF4444",
    "strokeWeight": 1
})
create_layer("text", "Auth CTA Text", 232, 244, 180, 20, parent=s2_id, text="Authorize & Connect", props={
    "fontSize": 14,
    "fontFamily": "Inter",
    "fontStyle": "Bold",
    "fill": "#FFFFFF"
})

print("[+] Completed Screen 2: Controller Auth Modal (Clean, No Emojis)")

# ==============================================================================
# SCREEN 3: Floating Session Toolbar (480 x 70) - ZERO EMOJIS
# ==============================================================================
s3_id = create_layer("frame", "RVDesk - Session Toolbar", 1020, 380, 480, 70, props={
    "fill": "#070A0F",
    "cornerRadius": 35,
    "stroke": "#1E293B",
    "strokeWeight": 1,
    "clip": True
})

bar_bg = create_layer("rectangle", "Toolbar Capsule", 10, 10, 460, 50, parent=s3_id, props={
    "fill": "#0F172A",
    "cornerRadius": 25,
    "stroke": "#334155",
    "strokeWeight": 1
})

create_layer("ellipse", "Live Dot", 26, 30, 10, 10, parent=s3_id, props={
    "fill": "#10B981"
})
create_layer("text", "Live Device Tag", 44, 26, 120, 20, parent=s3_id, text="#948 201 582", props={
    "fontSize": 12,
    "fontFamily": "Inter",
    "fontStyle": "Bold",
    "fill": "#FFFFFF"
})

# Tool Items (Clean text indicators, ZERO EMOJIS)
create_layer("rectangle", "Tool Box 1", 168, 20, 60, 30, parent=s3_id, props={
    "fill": "#1E293B",
    "cornerRadius": 6
})
create_layer("text", "Tool Text 1", 178, 27, 40, 16, parent=s3_id, text="HD 60", props={
    "fontSize": 11,
    "fontFamily": "Inter",
    "fontStyle": "Bold",
    "fill": "#CBD5E1"
})

create_layer("rectangle", "Tool Box 2", 236, 20, 56, 30, parent=s3_id, props={
    "fill": "#1E293B",
    "cornerRadius": 6
})
create_layer("text", "Tool Text 2", 246, 27, 36, 16, parent=s3_id, text="FILES", props={
    "fontSize": 10,
    "fontFamily": "Inter",
    "fontStyle": "Bold",
    "letterSpacing": 0.5,
    "fill": "#94A3B8"
})

create_layer("rectangle", "Tool Box 3", 300, 20, 56, 30, parent=s3_id, props={
    "fill": "#1E293B",
    "cornerRadius": 6
})
create_layer("text", "Tool Text 3", 312, 27, 34, 16, parent=s3_id, text="CHAT", props={
    "fontSize": 10,
    "fontFamily": "Inter",
    "fontStyle": "Bold",
    "letterSpacing": 0.5,
    "fill": "#94A3B8"
})

# End Session Red Button
create_layer("rectangle", "Disconnect Btn", 366, 18, 94, 34, parent=s3_id, props={
    "fill": "#DC2626",
    "cornerRadius": 8
})
create_layer("text", "Disconnect Text", 378, 26, 75, 20, parent=s3_id, text="Disconnect", props={
    "fontSize": 11,
    "fontFamily": "Inter",
    "fontStyle": "Bold",
    "fill": "#FFFFFF"
})

print("[+] Completed Screen 3: Floating Session Toolbar (Clean, No Emojis)")

# ==============================================================================
# SAVE AND EXPORT
# ==============================================================================
save_path = os.path.abspath(r"assets\rvdesk_redesign.figcraft")
os.makedirs(os.path.dirname(save_path), exist_ok=True)

save_res = call_mcp("tools/call", {
    "name": "save_file",
    "arguments": {
        "path": save_path
    }
})
print("[+] Saved clean .figcraft file to:", save_path)

proc.terminate()
print("[*] All tasks finished successfully!")
