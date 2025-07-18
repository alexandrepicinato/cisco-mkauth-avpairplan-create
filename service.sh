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
