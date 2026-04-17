// =============================================================================
// Plantilla: Autenticación Adaptativa — 2FA basado en IP
// Producto:  WSO2 Identity Server
//
// Solicita segundo factor (TOTP) cuando el login viene de una IP
// fuera del rango corporativo.
//
// Variable: {{CORPORATE_IPS}} - Array de rangos CIDR corporativos
// =============================================================================

var corporateIPs = {{CORPORATE_IPS}};
// Ejemplo: var corporateIPs = ["10.0.0.0/8", "192.168.1.0/24", "172.16.0.0/12"];

var onLoginRequest = function(context) {
    executeStep(1, {
        onSuccess: function(context) {
            var user = context.currentKnownSubject;
            var clientIP = context.request.ip;
            
            Log.info("[Adaptive Auth] Usuario: " + user.username + 
                     " | IP: " + clientIP);
            
            var isCorpIP = isCorporateIP(clientIP);
            
            if (!isCorpIP) {
                Log.info("[Adaptive Auth] IP externa detectada. Requiriendo 2FA.");
                executeStep(2);
            } else {
                Log.info("[Adaptive Auth] IP corporativa. Acceso directo.");
            }
        }
    });
};

function isCorporateIP(ip) {
    for (var i = 0; i < corporateIPs.length; i++) {
        if (isWithinCIDR(ip, corporateIPs[i])) {
            return true;
        }
    }
    return false;
}

function isWithinCIDR(ip, cidr) {
    var parts = cidr.split("/");
    var baseIP = parts[0];
    var maskBits = parseInt(parts[1]);
    
    var ipNum = ipToNumber(ip);
    var baseNum = ipToNumber(baseIP);
    var mask = (-1 << (32 - maskBits)) >>> 0;
    
    return (ipNum & mask) === (baseNum & mask);
}

function ipToNumber(ip) {
    var parts = ip.split(".");
    return ((parseInt(parts[0]) << 24) |
            (parseInt(parts[1]) << 16) |
            (parseInt(parts[2]) << 8) |
            parseInt(parts[3])) >>> 0;
}
