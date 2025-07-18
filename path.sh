#!/bin/bash

# Variáveis
DIR="/xandaoart/mod"
SCRIPT="$DIR/cisco.sh"
EXECUTOR="$DIR/executor.sh"
SERVICE="/etc/init.d/cisco-executor"
MYSQL_USER="root"
MYSQL_PASS="vertrigo"
MYSQL_DB="mkradius"
PIDFILE="/var/run/cisco-executor.pid"
LOGFILE="/var/log/cisco-executor.log"

echo "🚀 Iniciando instalação do executor Cisco..."

# Cria diretório se não existir
mkdir -p "$DIR"

# Cria script cisco.sh
cat > "$SCRIPT" <<EOF
#!/bin/bash
MYSQL_USER="$MYSQL_USER"
MYSQL_PASS="$MYSQL_PASS"
MYSQL_DB="$MYSQL_DB"

mysql -u "\$MYSQL_USER" -p"\$MYSQL_PASS" -D "\$MYSQL_DB" -N -e "SELECT DISTINCT groupname FROM radgroupreply;" | while read -r groupname; do
    for direction in In Out; do
        EXISTS=\$(mysql -u "\$MYSQL_USER" -p"\$MYSQL_PASS" -D "\$MYSQL_DB" -N -e "
            SELECT COUNT(*) FROM radgroupreply
            WHERE groupname = '\$groupname'
              AND attribute = 'Cisco-AvPair'
              AND value LIKE 'ip:sub-policy-\${direction}=%';
        ")

        if [ "\$EXISTS" -eq 0 ]; then
            echo "✔️ Criando regra \$direction para \$groupname"
            mysql -u "\$MYSQL_USER" -p"\$MYSQL_PASS" -D "\$MYSQL_DB" -e "
                INSERT INTO radgroupreply (groupname, attribute, op, value)
                VALUES ('\$groupname', 'Cisco-AvPair', '+=', 'ip:sub-policy-\${direction}=\${groupname}-\${direction}');
            "
        fi
    done
done
EOF

chmod +x "$SCRIPT"
echo "✔ Script cisco.sh criado."

# Cria executor.sh
cat > "$EXECUTOR" <<EOF
#!/bin/bash
while true; do
    $SCRIPT
    sleep 5
done
EOF

chmod +x "$EXECUTOR"
echo "✔ Script executor.sh criado."

# Cria serviço init.d
cat > "$SERVICE" <<EOF
#!/bin/sh
### BEGIN INIT INFO
# Provides:          cisco-executor
# Required-Start:    \$network
# Required-Stop:     
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Description:       Executa script cisco.sh a cada 5 segundos
### END INIT INFO

EXEC="$EXECUTOR"
PIDFILE="$PIDFILE"
LOGFILE="$LOGFILE"

case "\$1" in
  start)
    echo "▶️ Iniciando executor"
    nohup "\$EXEC" > "\$LOGFILE" 2>&1 &
    echo \$! > "\$PIDFILE"
    ;;
  stop)
    echo "⏹ Parando executor"
    [ -f "\$PIDFILE" ] && kill \$(cat "\$PIDFILE") && rm -f "\$PIDFILE"
    ;;
  restart)
    \$0 stop
    sleep 1
    \$0 start
    ;;
  status)
    if [ -f "\$PIDFILE" ]; then
        echo "✅ Executor rodando. PID: \$(cat \$PIDFILE)"
    else
        echo "❌ Executor não está em execução."
    fi
    ;;
  *)
    echo "Uso: \$0 {start|stop|restart|status}"
    exit 1
esac

exit 0
EOF

chmod +x "$SERVICE"
echo "✔ Serviço init.d criado."

# Registrar serviço para iniciar no boot
if command -v update-rc.d &>/dev/null; then
    update-rc.d cisco-executor defaults
    echo "✔ Serviço registrado para iniciar no boot."
else
    echo "⚠️ update-rc.d não encontrado. Registre o serviço manualmente."
fi

# Inicia o serviço
"$SERVICE" start

echo "✅ Instalação concluída. Serviço iniciado."
echo "Use '$SERVICE {start|stop|restart|status}' para controlar o executor."
