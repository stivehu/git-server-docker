# edge: jelenleg az egyetlen Alpine ag, amiben az openssh >= 10.6_p2 elerheto
# (a 3.22/3.23 meg a serulekeny 10.0/10.2 verziot szallitja). Ha a stabil
# agba bekerul a backport, visszavalthato egy rogzitett tagre.
FROM alpine:edge

LABEL maintainer="Gábor István <stive.hu@gmail.com>, Carlos Bernárdez <carlos@z4studios.com>"

# openssh >= 10.6_p2 tartalmazza a CVE-2026-123158 javitasat (musl jelszavas
# auth bypass). A verzio-floor miatt a build inkabb elbukik, mintsem hogy
# eszrevetlenul serulekeny openssh-t telepitsen.
RUN apk add --no-cache git \
  && apk add --no-cache "openssh>=10.6_p2"

# Key generation on the server
RUN ssh-keygen -A

# SSH autorun
# RUN rc-update add sshd

WORKDIR /git-server/

# -D flag avoids password generation
# -s flag changes user's shell
# A 'git' usernek szandekosan NINCS jelszava (adduser -D) -- a belepes kizarolag
# kulccsal tortenik. Jelszo-hash nelkul a CVE-2026-123158 bypass elofeltetele
# sem teljesul, meg akkor sem, ha a PasswordAuthentication valaha bekapcsolodna.
RUN mkdir /git-server/keys \
  && adduser -D -s /usr/bin/git-shell git \
  && mkdir /home/git/.ssh

# This is a login shell for SSH accounts to provide restricted Git access.
# It permits execution only of server-side Git commands implementing the
# pull/push functionality, plus custom commands present in a subdirectory
# named git-shell-commands in the user’s home directory.
# More info: https://git-scm.com/docs/git-shell
COPY git-shell-commands /home/git/git-shell-commands

# sshd_config file is edited for enable access key and disable access password
COPY sshd_config /etc/ssh/sshd_config
COPY start.sh start.sh

EXPOSE 22

CMD ["sh", "start.sh"]
