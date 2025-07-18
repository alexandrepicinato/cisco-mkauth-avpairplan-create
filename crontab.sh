#!/bin/bash

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
