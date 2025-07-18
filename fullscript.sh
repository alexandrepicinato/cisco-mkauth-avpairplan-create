#!/bin/bash

# Configuração de conexão
MYSQL_USER="root"
MYSQL_PASS="vertrigo"
MYSQL_DB="mkradius"

# Buscar todos os groupnames únicos
mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -N -e "
SELECT DISTINCT groupname FROM radgroupreply;
" | while read groupname; do

    # Verifica se a regra IN já existe
    EXISTS_IN=$(mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -N -e "
        SELECT COUNT(*) FROM radgroupreply
        WHERE groupname = '$groupname'
          AND attribute = 'Cisco-AvPair'
          AND value LIKE 'ip:sub-policy-In=%';
    ")

    if [ "$EXISTS_IN" -eq 0 ]; then
        echo "Criando regra IN para $groupname"
        mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -e "
            INSERT INTO radgroupreply (groupname, attribute, op, value)
            VALUES ('$groupname', 'Cisco-AvPair', '+=', 'ip:sub-policy-In=${groupname}-IN');
        "
    fi

    # Verifica se a regra OUT já existe
    EXISTS_OUT=$(mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -N -e "
        SELECT COUNT(*) FROM radgroupreply
        WHERE groupname = '$groupname'
          AND attribute = 'Cisco-AvPair'
          AND value LIKE 'ip:sub-policy-Out=%';
    ")

    if [ "$EXISTS_OUT" -eq 0 ]; then
        echo "Criando regra OUT para $groupname"
        mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -e "
            INSERT INTO radgroupreply (groupname, attribute, op, value)
            VALUES ('$groupname', 'Cisco-AvPair', '+=', 'ip:sub-policy-Out=${groupname}-OUT');
        "
    fi
done


# Variáveis
DIR="/xandaoart/mod"
SCRIPT="$DIR/cisco.sh"
PHP_SCRIPT="/opt/mk-auth/admin/executar_cisco.php"
WEB_USER="www-data"   # Ajuste se seu servidor web usar outro usuário

# 1. Cria diretório e script cisco.sh
mkdir -p "$DIR"

cat << 'EOF' > "$SCRIPT"
#!/bin/bash

# Configuração de conexão
MYSQL_USER="root"
MYSQL_PASS="vertrigo"
MYSQL_DB="mkradius"

# Buscar todos os groupnames únicos
mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -N -e "
SELECT DISTINCT groupname FROM radgroupreply;
" | while read groupname; do

    # Verifica se a regra IN já existe
    EXISTS_IN=$(mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -N -e "
        SELECT COUNT(*) FROM radgroupreply
        WHERE groupname = '$groupname'
          AND attribute = 'Cisco-AvPair'
          AND value LIKE 'ip:sub-policy-In=%';
    ")

    if [ "$EXISTS_IN" -eq 0 ]; then
        echo "Criando regra IN para $groupname"
        mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -e "
            INSERT INTO radgroupreply (groupname, attribute, op, value)
            VALUES ('$groupname', 'Cisco-AvPair', '+=', 'ip:sub-policy-In=${groupname}-IN');
        "
    fi

    # Verifica se a regra OUT já existe
    EXISTS_OUT=$(mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -N -e "
        SELECT COUNT(*) FROM radgroupreply
        WHERE groupname = '$groupname'
          AND attribute = 'Cisco-AvPair'
          AND value LIKE 'ip:sub-policy-Out=%';
    ")

    if [ "$EXISTS_OUT" -eq 0 ]; then
        echo "Criando regra OUT para $groupname"
        mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -e "
            INSERT INTO radgroupreply (groupname, attribute, op, value)
            VALUES ('$groupname', 'Cisco-AvPair', '+=', 'ip:sub-policy-Out=${groupname}-OUT');
        "
    fi
done
EOF

chmod +x "$SCRIPT"
echo "✅ Script shell criado em $SCRIPT e tornado executável."

# 2. Cria script PHP para executar o shell script
cat << EOF > "$PHP_SCRIPT"
<?php
// Caminho do script shell
\$shellScript = escapeshellarg('$SCRIPT');

// Executa o script shell e captura a saída e o status
exec("bash " . \$shellScript . " 2>&1", \$output, \$return_var);

// Exibe a saída formatada
echo "<pre>";
if (\$return_var === 0) {
    echo "Script executado com sucesso:\\n\\n";
    echo implode("\\n", \$output);
} else {
    echo "Erro ao executar o script (Código \$return_var):\\n\\n";
    echo implode("\\n", \$output);
}
echo "</pre>";
?>
EOF

# Ajusta dono e permissões para o usuário web
chown "$WEB_USER":"$WEB_USER" "$PHP_SCRIPT"
chmod 644 "$PHP_SCRIPT"
echo "✅ Script PHP criado em $PHP_SCRIPT com permissões corretas."
# 3. Configura crontab para rodar o script a cada minuto, evitando duplicação
(crontab -l 2>/dev/null | grep -v "$SCRIPT"; echo "* * * * * $SCRIPT") | crontab -


DIR="/xandaoart/mod"
SCRIPT="$DIR/cisco.sh"
PHP_SCRIPT="/opt/mk-auth/admin/executar_cisco.php"
WEB_USER="www-data"

mkdir -p "$DIR"

cat << 'EOF' > "$SCRIPT"
#!/bin/bash

MYSQL_USER="root"
MYSQL_PASS="vertrigo"
MYSQL_DB="mkradius"

mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -N -e "
SELECT DISTINCT groupname FROM radgroupreply;
" | while read groupname; do

    EXISTS_IN=$(mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -N -e "
        SELECT COUNT(*) FROM radgroupreply
        WHERE groupname = '$groupname'
          AND attribute = 'Cisco-AvPair'
          AND value LIKE 'ip:sub-policy-In=%';
    ")

    if [ "$EXISTS_IN" -eq 0 ]; then
        mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -e "
            INSERT INTO radgroupreply (groupname, attribute, op, value)
            VALUES ('$groupname', 'Cisco-AvPair', '+=', 'ip:sub-policy-In=${groupname}-IN');
        "
    fi

    EXISTS_OUT=$(mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -N -e "
        SELECT COUNT(*) FROM radgroupreply
        WHERE groupname = '$groupname'
          AND attribute = 'Cisco-AvPair'
          AND value LIKE 'ip:sub-policy-Out=%';
    ")

    if [ "$EXISTS_OUT" -eq 0 ]; then
        mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -e "
            INSERT INTO radgroupreply (groupname, attribute, op, value)
            VALUES ('$groupname', 'Cisco-AvPair', '+=', 'ip:sub-policy-Out=${groupname}-OUT');
        "
    fi
done
EOF

chmod +x "$SCRIPT"

cat << EOF > "$PHP_SCRIPT"
<?php
\$shellScript = escapeshellarg('$SCRIPT');
exec("bash " . \$shellScript . " 2>&1", \$output, \$return_var);
echo "<pre>";
if (\$return_var === 0) {
    echo "Script executado com sucesso:\\n\\n";
    echo implode("\\n", \$output);
} else {
    echo "Erro ao executar o script (Código \$return_var):\\n\\n";
    echo implode("\\n", \$output);
}
echo "</pre>";
?>
EOF

chown "$WEB_USER":"$WEB_USER" "$PHP_SCRIPT"
chmod 644 "$PHP_SCRIPT"

(crontab -l 2>/dev/null | grep -v "$SCRIPT"; echo "* * * * * $SCRIPT") | crontab -


#!/bin/bash

# Configurações
SCRIPT_DIR="/xandaoart/mod"
SCRIPT_EXEC="$SCRIPT_DIR/cisco.sh"
EXECUTOR_SCRIPT="$SCRIPT_DIR/executor.sh"
SERVICE_FILE="/etc/init.d/cisco-executor"
LOG_FILE="/var/log/cisco-executor.log"
PID_FILE="/var/run/cisco-executor.pid"

# Cria o diretório, se necessário
mkdir -p "$SCRIPT_DIR"

# Cria o script cisco.sh, caso não exista
if [ ! -f "$SCRIPT_EXEC" ]; then
cat <<'EOF' > "$SCRIPT_EXEC"
#!/bin/bash
MYSQL_USER="root"
MYSQL_PASS="vertrigo"
MYSQL_DB="mkradius"

mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -N -e "
SELECT DISTINCT groupname FROM radgroupreply;
" | while read groupname; do

    EXISTS_IN=$(mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -N -e "
        SELECT COUNT(*) FROM radgroupreply
        WHERE groupname = '$groupname'
          AND attribute = 'Cisco-AvPair'
          AND value LIKE 'ip:sub-policy-In=%';
    ")

    if [ "$EXISTS_IN" -eq 0 ]; then
        mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -e "
            INSERT INTO radgroupreply (groupname, attribute, op, value)
            VALUES ('$groupname', 'Cisco-AvPair', '+=', 'ip:sub-policy-In=${groupname}-IN');
        "
    fi

    EXISTS_OUT=$(mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -N -e "
        SELECT COUNT(*) FROM radgroupreply
        WHERE groupname = '$groupname'
          AND attribute = 'Cisco-AvPair'
          AND value LIKE 'ip:sub-policy-Out=%';
    ")

    if [ "$EXISTS_OUT" -eq 0 ]; then
        mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -e "
            INSERT INTO radgroupreply (groupname, attribute, op, value)
            VALUES ('$groupname', 'Cisco-AvPair', '+=', 'ip:sub-policy-Out=${groupname}-OUT');
        "
    fi
done
EOF
chmod +x "$SCRIPT_EXEC"
fi

# Cria o executor que roda a cada 5 segundos
cat <<EOF > "$EXECUTOR_SCRIPT"
#!/bin/bash
while true; do
    bash "$SCRIPT_EXEC"
    sleep 5
done
EOF
chmod +x "$EXECUTOR_SCRIPT"

# Cria o serviço init.d
cat <<EOF > "$SERVICE_FILE"
#!/bin/sh
### BEGIN INIT INFO
# Provides:          cisco-executor
# Required-Start:    \$network
# Required-Stop:     
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Executor de cisco.sh a cada 5 segundos
### END INIT INFO

case "\$1" in
  start)
    echo "Iniciando cisco.sh"
    nohup "$EXECUTOR_SCRIPT" > "$LOG_FILE" 2>&1 &
    echo \$! > "$PID_FILE"
    ;;
  stop)
    echo "Parando cisco.sh"
    kill \$(cat "$PID_FILE") 2>/dev/null
    rm -f "$PID_FILE"
    ;;
  restart)
    \$0 stop
    sleep 1
    \$0 start
    ;;
  status)
    if [ -f "$PID_FILE" ]; then
        echo "Rodando. PID: \$(cat $PID_FILE)"
    else
        echo "Não está em execução."
    fi
    ;;
  *)
    echo "Uso: /etc/init.d/cisco-executor {start|stop|restart|status}"
    exit 1
esac

exit 0
EOF

# Ativa permissões e habilita no boot
chmod +x "$SERVICE_FILE"
update-rc.d cisco-executor defaults

# Inicia serviço imediatamente
/etc/init.d/cisco-executor start

#!/bin/bash

SRC_PATH="/xandaoart/executar_cisco.php"
DEST_DIR="/opt/mk-auth/admin/cisco"
DEST_PATH="$DEST_DIR/index.php"

# Cria diretórios se não existirem
mkdir -p "/xandaoart"
mkdir -p "$DEST_DIR"

# Cria o script PHP principal
cat <<'EOF' > "$SRC_PATH"
<?php

$host = 'localhost';
$user = 'root';
$pass = 'vertrigo';
$db   = 'mkradius';

$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    die("❌ Erro na conexão: " . $conn->connect_error);
}

$sql = "SELECT DISTINCT groupname FROM radgroupreply";
$result = $conn->query($sql);

if (!$result) {
    die("❌ Erro na consulta: " . $conn->error);
}

while ($row = $result->fetch_assoc()) {
    $groupname = $conn->real_escape_string($row['groupname']);

    $checkIn = "SELECT COUNT(*) as total FROM radgroupreply 
                WHERE groupname = '$groupname' 
                  AND attribute = 'Cisco-AvPair' 
                  AND value LI




echo "✅ Instalação completa. Serviço 'cisco-executor' criado, iniciado e configurado para iniciar no boot."


