# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     App.Repo.insert!(%App.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias App.{Repo, HnswlibIndex}

if env == :test  do
  # reset
  Repo.delete_all(HnswlibIndex)

  # Create index file with some sample image
  Repo.insert!(%HnswlibIndex{lock_version: 3, file: "        È                                                                       þ +eG ×?È                                                                                                                                           4 7¼§í <jÆ¥º [Ì»]° ½¢  <u È¼Éä.=Mä <î®¨¼©  ¼Lqµ»Ò]«<BÆ ½ ±³½Ü  =Ó\\µ=BE ¼Õ ö¼SB <Lä ¼õóf¼â °;tª =ay(½   =äf <Éñ ¼a´È¼ J¤<K$ =õÞá¼õ  ¼[( ¼}á!<x <½ ÞY<¶ Ö<mË ½ SL<_$ ¼]Ñ ¼9[Þ½  ð=2ÙS½ Â_¼á8°½\\aí»& ¥<  \";6kØ½ ®@¼Á ß¸V  ¼¢ °< ´G= h¨=ÁàO; 9M=÷  <? 4= ÷ =(³ <LõW½ð¦v½ ì+½,ÿ ;ÑâØ½ C¶»h¼3½ ¾ ½ÕÂP=/Ä?½Éá =9u_=çÁy=ª  ½ªS =«ç ½V  =½  =~ ã<îNé=*  ¼^ \'½ ¬ <\'ò <P  =Ìÿ ¼ K×<DK=<®b ¼J[ ½ARÄ=³ Ý=û-~½ô:i½Á  ;Qa ¾ õÍ¼©0 =á+=½\"»\'½æR§¼@]g¼Ý ¾¼ã x= 8 :É  ½ tb= K/=µ_ <}° <ã¿o¼Y  =q 5< , ½  £½ Vü¼ Ã¥=Qe±=~ à»åQ = +}=  r½   ½/H{=0êÃ¼¶2 ½ Ú×<  «=ÑE¾½ v1¼£ ¡º N ½  Z=ß­¥½ ¯0¼nC$<  Î=@ ã= ]Ç½   <   ½ØÀÝ=buÖºY ç½  K¼ip±7Ð] ¼Ï »=  Ê¼ê ã¼ø¶¾=A0A½±\'&= ë4<þWÍ¼   ½<¨ ½r?Æ¼ôq ½ÀVQ=ä§í;¡Õ < £ ½/Áª< çü¼  D½å N½÷  »v¨ = Í¡¼uke½  .<§ ,= ¿ò<*  ½¸þ <ÀÞc½hÄ,=H ¯½;/ò¼f> ½ \\T=¥¶Ã¼¢¡ < oÕ< YÜ= æº½ù ¯»[ L<ÃðY½7£Ô<  «<ýþ ºþ@!½tn ¼*=x=\" d¼kþ =  Ð; Èw½dL®= Á9=¥  =^½á¼j è½ 7à< >y;_  =¶ÜR=<·p<Ï` ½øõh½È\\>¼   <QÑù=å¦ =«, 8z<è9õ {<¯  = 0 ½QÒÎ½ øD=Û ë¼   ½ªè ¼ ¿È=Ezd½g®ä<q1Í<ä å= ªé¼(î =GµS¼  p; vN=«× ¼o\"Ø½£YN= ¥ñ¼ã ý¼ ¸É½D  =A.°<ð)Ü<±Ñk=sKÄ½ÂÒ = âò<Q  =v »=åª5½{ø ¼+ Í¼ í ½îÐ¥<G;+<ï4 :d/Ì»$É(½]Æ3=íj ½ k0= v\'=4  :ä Ã<éÙy½·JS<«°&=ÚÞ1½Öy ½ Df=Nt³»g 5<<ÏË½èÕ#=Jjÿ<¸  ¼¤C =Fêø<N $½ÏíM= ê_½$Ïª< åD½RÑ = ´G=58-=ås ¼Jbè¼§ÀÓ¼ÏRè;ã®\'=ËjG= ªç=l ¶<3ìe½_wì» g/½ ² =±ÍE½Á  ½   »&¡ ¼T  ¼ß¯ »@Tô»ü ­=øck=i  <[ÁE=_ 9¼U 1¼  üº ó¯½  û¼mXk½ <±<NàE½ ïÇ»ã  =ý  <Î ³½vp ¼  t=k»F½  Á¼  r;¸¥ ½kW =\\s¤= t¢»   ½Ô7«;FQ =\\  < pñ;C×*=e¢ ½i  ½ XÕ¼ ö­=¨Äâ½p` =Û  =Wa <ý Á<8 ì< 2 ½´Õ¿:$èé¼ ½æ½  °½  Á»Þ  <$û = ®à8 àb¼ * ¼/tT½½R ½NÓO= ¼4½Òÿª<û  ¼ Bi=wU »   ½ ì»<¾¶á=L L;zÉ ½ v ½ öÀ½ó É= cÃ½L/ ½ ¡ <<Kµ<Çq ½8tÖ9            "})
end
