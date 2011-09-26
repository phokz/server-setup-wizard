#!/bin/bash

export LC_ALL=en_US.utf8
dialog --title "První přihlášení"  --yesno "Toto je vaše první přihlášení. Chcete spustit průvodce nastavením?" 10 40


if [ $? = 0 ]; then
  #remove hook
  sed -i 's/first.sh/#first.sh/' ~/.profile
  wizard.sh
else
  #remove hook
  sed -i 's/first.sh/#first.sh/' ~/.profile
  echo "Průvodce můžete spustit později pomocí příkazu wizard.sh"
fi

