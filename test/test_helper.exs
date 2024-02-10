# Seed the database first with data for testing ----
alias App.{Repo, HnswlibIndex}

Repo.delete_all(HnswlibIndex)
# Repo.insert!(%HnswlibIndex{
#   id: 1,
#   lock_version: 3,
#   file:
# """
#         È                                                                       þ +eG ×?È                                                                                                                                           4 7¼§í <jÆ¥º [Ì»]° ½¢  <u È¼Éä.=Mä <î®¨¼©  ¼Lqµ»Ò]«<BÆ ½ ±³½Ü  =Ó\µ=BE ¼Õ ö¼SB <Lä ¼õóf¼â °;tª =ay(½   =äf <Éñ ¼a´È¼ J¤<K$ =õÞá¼õ  ¼[( ¼}á!<x <½ ÞY<¶ Ö<mË ½ SL<_$ ¼]Ñ ¼9[Þ½  ð=2ÙS½ Â_¼á8°½\aí»& ¥<  ";6kØ½ ®@¼Á ß¸V  ¼¢ °< ´G= h¨=ÁàO; 9M=÷  <? 4= ÷ =(³ <LõW½ð¦v½ ì+½,ÿ ;ÑâØ½ C¶»h¼3½ ¾ ½ÕÂP=/Ä?½Éá =9u_=çÁy=ª  ½ªS =«ç ½V  =½  =~ ã<îNé=*  ¼^ '½ ¬ <'ò <P  =Ìÿ ¼ K×<DK=<®b ¼J[ ½ARÄ=³ Ý=û-~½ô:i½Á  ;Qa ¾ õÍ¼©0 =á+=½"»'½æR§¼@]g¼Ý ¾¼ã x= 8 :É  ½ tb= K/=µ_ <}° <ã¿o¼Y  =q 5< , ½  £½ Vü¼ Ã¥=Qe±=~ à»åQ = +}=  r½   ½/H{=0êÃ¼¶2 ½ Ú×<  «=ÑE¾½ v1¼£ ¡º N ½  Z=ß­¥½ ¯0¼nC$<  Î=@ ã= ]Ç½   <   ½ØÀÝ=buÖºY ç½  K¼ip±7Ð] ¼Ï »=  Ê¼ê ã¼ø¶¾=A0A½±'&= ë4<þWÍ¼   ½<¨ ½r?Æ¼ôq ½ÀVQ=ä§í;¡Õ < £ ½/Áª< çü¼  D½å N½÷  »v¨ = Í¡¼uke½  .<§ ,= ¿ò<*  ½¸þ <ÀÞc½hÄ,=H ¯½;/ò¼f> ½ \T=¥¶Ã¼¢¡ < oÕ< YÜ= æº½ù ¯»[ L<ÃðY½7£Ô<  «<ýþ ºþ@!½tn ¼*=x=" d¼kþ =  Ð; Èw½dL®= Á9=¥  =^½á¼j è½ 7à< >y;_  =¶ÜR=<·p<Ï` ½øõh½È\>¼   <QÑù=å¦ =«, 8z<è9õ {<¯  = 0 ½QÒÎ½ øD=Û ë¼   ½ªè ¼ ¿È=Ezd½g®ä<q1Í<ä å= ªé¼(î =GµS¼  p; vN=«× ¼o"Ø½£YN= ¥ñ¼ã ý¼ ¸É½D  =A.°<ð)Ü<±Ñk=sKÄ½ÂÒ = âò<Q  =v »=åª5½{ø ¼+ Í¼ í ½îÐ¥<G;+<ï4 :d/Ì»$É(½]Æ3=íj ½ k0= v'=4  :ä Ã<éÙy½·JS<«°&=ÚÞ1½Öy ½ Df=Nt³»g 5<<ÏË½èÕ#=Jjÿ<¸  ¼¤C =Fêø<N $½ÏíM= ê_½$Ïª< åD½RÑ = ´G=58-=ås ¼Jbè¼§ÀÓ¼ÏRè;ã®'=ËjG= ªç=l ¶<3ìe½_wì» g/½ ² =±ÍE½Á  ½   »&¡ ¼T  ¼ß¯ »@Tô»ü ­=øck=i  <[ÁE=_ 9¼U 1¼  üº ó¯½  û¼mXk½ <±<NàE½ ïÇ»ã  =ý  <Î ³½vp ¼  t=k»F½  Á¼  r;¸¥ ½kW =\s¤= t¢»   ½Ô7«;FQ =\  < pñ;C×*=e¢ ½i  ½ XÕ¼ ö­=¨Äâ½p` =Û  =Wa <ý Á<8 ì< 2 ½´Õ¿:$èé¼ ½æ½  °½  Á»Þ  <$û = ®à8 àb¼ * ¼/tT½½R ½NÓO= ¼4½Òÿª<û  ¼ Bi=wU »   ½ ì»<¾¶á=L L;zÉ ½ v ½ öÀ½ó É= cÃ½L/ ½ ¡ <<Kµ<Çq ½8tÖ9                                                                                                                                            ¡  =YÔ =µÇã¼3D_;$  ½®T ¼5IA<ëCÒ<V =½fÌÂ<¤Ý³¼ë¿ =tþ <¹ X:  ?½ãfO=Éß¿=ÚDS½   ½ ÈB<kèK=B R»¦r »¿ 1½¡B ½äK1= 9L½xÄ+= Ð =êP = Øn¼x  ¼\úD½ré`=õÆþ¼½Y®¸  [=¢y =#  ¼> æ<$  =½I¦;~®h½î  =úUõ¼û_*=)AË½H¡ =bx <éh = 7½½ :#<X¹ =ú @½½  ¼ N±=Ip =û$ÿ< â =¸  = ÿõ<ÀÑ =  6:Öp =Áàï¼U¦ ½öÕd½ëÅ®»ç´ù< ²l¼ / <¦Ï.=HW ½òb ½åg;¼7R´=îâG½¶ç_= Z²½sON=ÌÛ)=0 1¼SzÎ=Åú­½   ½ Ôp½bÌæ;w ®=^-(½Ï®·=hr§<èÕ ½ õÐ½Eo©<  Ê» 8 ½Ã½ ¼(;K½û ½½o( <m \=í :<MÔØ¼Ô G:?ýu¼t  ½$Âø»=¤3= »-¼ µm=pÔô<9 +=ûoT<Eð4;õ$z½ Ç­»±Þ9<{ ¸: D ½±Û0=­Õ =Nû ½{÷ ;¸À®<jÀx¼zØÙ¼bú ¼Ã §½ í ½ uë»G(ò<Ë» ½)VÀº2ôî¼   ½ú  <o?Ò½öÛï<  É;Å  >X ö=È=¹½¹× =J¡+½ r =   <, z¼ûvN:/}c½¾îÏ;áð =äà ½äÃv½-\ ;ès ½$ù¿=6 B½q¿ ¼T  »Òè ½Ò Í:óC(½ åt=Ë? ½q ¦»3³¨¼®Z]=yoú; BL½K ^:Æí]½ .M¼+A <  ¶¼Q ¼<ès¤=ý  ; ð ½ \R<b©­¼ ìñ=%v ½I ê¼ ÐÆ¼N¹==8$Å=¾WO¼ YX=< «= Nv½)ß < ½H¼K¶y¼5 û<ÂöG¼ ËR½® ½½ï¿¶;í Ý»û  ½l¶*½  $= ° ½þ T= ¸¦¼Ð4 =6áG½sÔÇ½±ö ½:íÌ<Ð ¿=\1¨<+ò <fÓå¼~!_½ ÓÀ;b H=BÇ¢=÷h­=w M¼ F\=oèô¼ É =\³Ø½H U½  ä» Q = )¨½+ µ½ y =x¨ ½öA =   =;I¼=÷ &=  p<þ©V½}qY<>ð|=a W=(õ|½X© >%Û¶¼|5¦<  å½mÍd= ¨ª=-$²=¸qF<¥² ½};7=ê I=ñ¬Ü¼  )=ðIQ½¶à <FéÉ»< #½§  ;.éä; µ ½2  ½# G½w ­<AZ<½Õ@È¼  É=>5 <E+Ì<¼+f½L  ¼oeé;Å| ½ +Å¼ü K=|K =:D|¼·m ½ 6¯<-M »©íó;I ¥<P¹ =ëd < yQ<  O½ ¦ = 0`¼´` =E¬Ê= Jä¼;É§¼ux ½  O½ ½c¼:z ¼ 1 =  W=ý*ú<²Ò=½Æ M½jdÞ¼æ6 = Õ ¼  ×½ h#¼¦iª¼ ?Ú<B &<µMå¼  Á= 7*=¦à <Ík°<å ª½É¦ ¼L !=c¥¢½ÈO <eãÀ½lª ¼ L³½Út ½e¦±=ªz]¼ Ö¶½X^ ¼Óh =äco½åÅ < < =   ½"¿ =Éí =JJ <é Û½ý±q<Ä-[=hrk:ÿ Y=bä¥= Þ ½Y6 ¼ 5â½   =òº;¾­ ª= A ¼Fã°½sØ <Â >;  ù¼Lý = $ ½¹ Ï½dFs½Òk <GK´<ÄÝÅ=Þ ¸¼ É =S8 <1±Ê¼>1Z;³ì <ì)E½v  ºðMH;×( <« Ê<ü\ ½aÂ0<õ|«=d9Ä;å ö¸", <êç«½»§Å¼ á=½ =g½ã o=Òé ½  ©¼Ë %=
# """
# })

{:ok, file} =
  Application.app_dir(:app, ["priv", "static", "uploads"])
  |> Path.join("indexes_test.bin")
  |> File.read()

Repo.insert!(%HnswlibIndex{
  id: 1,
  lock_version: 3,
  file: file
})

# Start the KNN-search genserver that was not started in the `application.ex` for the database to be seeded ----------
{:ok, _} = Supervisor.start_child(App.Supervisor, {App.KnnIndex, :cosine}) |> dbg()

# Start tests ---------------
ExUnit.start()
# Ecto.Adapters.SQL.Sandbox.mode(App.Repo, :manual)
