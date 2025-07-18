Faca o clone do repositorio
Rode bash start.sh ou bash fullscript.sh com o usuario ROOT do mkauth

Crie as AV PAIRS NO Cisco om o mesmo nome do plano setado no MKAuth (nao pode conter espacos ou caracteries especiais )
Exemplo 
Criando polices no ASR #
policy-map Plano-Fibra-10Mbps-IN
 class class-default
  police 10m
policy-map Plano-Fibra-10Mbps-OUT
 class class-default
  police 10m
