#!/bin/bash
#
# AO EXECUTAR PELA PRIMEIRA VEZ CRIAR OS GRUPOS USUARIOS E COMPUTADOR
# TAMBEM CRIAR O exemplo.bat PARA A COPIA DE EXEMPO PARA NO NETLOGON
# ULTIMA ATUALIZACAO: 01/07/17
#
clear
Principal() {
	echo ""	
	echo ""	
	echo ""	
	echo "------------------------------------------"
	echo "CONTROLE DO DOMINIO"
	echo "------------------------------------------"
	echo "Opcao:"
	echo
	echo "1. Criar novo usuario"
	echo "2. Remover usuario"
	echo "3. Lista usuarios"
	echo "4. Alterar Senha de Usuario"
	echo "5. Adiciona Maquina no Dominio MATRIZ-WARRE"
	echo "6. Listar maquinas do DOMINIO"
	echo "7. Remove Maquina do Dominio"
	echo "8. Ir para o Terminal"
	echo
	echo -n "Qual a opcao desejada? "
	read opcao
	case $opcao in
		1) criarusuario ;;
		2) deletarusuario ;;
		3) listausuario ;;
		4) alterasenha ;;
		5) addmaquina ;;	
		6) listmaquina ;;
		7) delmaquina ;;	
		8) fim ;;
		*) "Opcao desconhecida." ; echo ; Principal ;;
	esac
}
criarusuario() {
	echo -n "Digite o nome do usuario? --->  "
	read usuario
	useradd -c "USUARIO" -g usuarios $usuario
	
#	mkdir /home/$usuario
	cp -R /home/netlogon/exemplo.bat /home/netlogon/$usuario.bat
#  	chown $usuario.usuarios -R /home/netlogon/$usuario.bat 
	mv /home/$usuario /home/usuarios
	echo "Usuario Criado..."
	echo ""	
#	passwd $usuario
	smbpasswd -a $usuario
	echo ""	
	echo "Definir os grupos do usuario!"
	echo "Edite o Arquivo de Logon do Usuario no netlogon"
    Principal
}
deletarusuario() {
	echo -n "Digite o nome do usuario? --->  "
	read usuario
	pdbedit -x $usuario
	echo ""	
	userdel $usuario
	echo ""	
	rm -Rf /home/usuarios/$usuario
	echo ""	
	rm -Rf /home/netlogon/$usuario.bat
	echo ""	
	echo "Usuario Removido..."
    Principal
}

listausuario (){
	echo -e "USUARIOS DO SERVIDOR SERVER-ARQ \n "
        echo ""
        echo -e "-:: PASSWD ::-"
	cat /etc/passwd |grep 500 
        echo ""
        echo -e "-:: SMBPASSWD (PDBEDIT) ::-"
	pdbedit -Lw |grep U
        Principal
}

addmaquina(){
	echo -n "Digite o nome da Maquina? (warreXX$) --->  "
	read addmaq
	useradd -g computadores -c "COMPUTADOR" -s /bin/false -d /dev/null/ $addmaq 
	smbpasswd -m -a $addmaq
        echo ""
	echo "Maquina adicionada ao dominio"
    Principal    
}
listmaquina(){
	echo -e "ESTAS MAQUINAS ESTAO NO DOMINIO \n "
        echo -e "-:: PASSWD ::-"
	cat /etc/passwd |grep COMPUTADOR
        echo ""
 	echo -e "-:: SMBPASSWD (PDBEDIT) ::-"
	pdbedit -Lw |grep W
        echo ""
	Principal
}
delmaquina(){
	echo -n "Digite o nome da Maquina? (warreXX$) --->  "
	read delmaq
	smbpasswd -x $delmaq	
	userdel $delmaq
        echo ""
	echo "Maquina REMOVIDA do dominio MATRIZ-WARRE"
    Principal
}
	alterasenha() {
	   echo -n "Digite o nome do usuario? ---> O Padrao: (usuario ou sobrenome)"
	   read usuario
           echo "------------------------------------------"
           echo "------------------------------------------"
	   echo "MODIFICACAO DE $usuario"
	   echo "------------------------------------------"
	   echo "Opcoes"
	   echo
	   echo "1. Alterar senha do CVS/Linux (NAO E NECESSARIO)"
	   echo "2. Alterar senha da rede"
	   echo "3. Alterar senha do CVS e da REDE"
	   echo "4. Voltar "
	   echo	
	   echo -n "Qual a opçao desejada? "
	   read opcao
	   case $opcao in
	      1) cvs ;;
	      2) rede ;;
	      3) cvsRede ;;
	      4) Principal ;;
	      *) "Opcao desconhecida." ; echo ; Principal ;;
	   esac
	}	
		rede() {
		    smbpasswd $usuario
 		    echo -n "senha da rede altera"
    		    Principal
		}
		cvs() {
		    passwd $usuario
                    echo -n "senha do CVS altera"
		    Principal
		}
		cvsRede() {
		    echo "CVS"
		    passwd $usuario
		    echo "REDE"
		    smbpasswd $usuario
                    echo -n "senha do CVS e da rede altera"
		    Principal
		}
		
fim() {
	echo " =D .... Obrigado volte sempre!!!"
    `exit`
}
Principal
