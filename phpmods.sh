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
