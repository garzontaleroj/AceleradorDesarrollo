// =============================================================================
// Script de Autenticación Adaptiva — Ejemplo
// Se configura en el Service Provider > Local & Outbound Authentication
// =============================================================================

// Autenticación condicional: si el usuario pertenece a un rol admin,
// se solicita un segundo factor (TOTP)
var onLoginRequest = function(context) {
    executeStep(1, {
        onSuccess: function(context) {
            var user = context.currentKnownSubject;
            var roles = user.roles;

            if (hasRole(roles, 'admin')) {
                Log.info('Usuario admin detectado — solicitando 2FA');
                executeStep(2);
            }
        }
    });
};

function hasRole(roles, roleName) {
    if (roles) {
        for (var i = 0; i < roles.length; i++) {
            if (roles[i] === roleName) {
                return true;
            }
        }
    }
    return false;
}
