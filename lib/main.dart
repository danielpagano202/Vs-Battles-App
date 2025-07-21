/*
-Get rid of entitlement after purchase is refunded
-Fix store front on play store
-Test run of app
-Get rid of test mode on ads
-Get rid of delay after purchase restoration
 */

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
enum Winner {
  Red,
  Blue,
}

enum PartOfSpeech{
  Noun,
  Adjective,
}

class Word{
  PartOfSpeech partOfSpeech = PartOfSpeech.Noun;
  String text = "";
  Word(PartOfSpeech pos, String text){
    partOfSpeech = pos;
    this.text = text;
  }
  Word.adjective(String text){
    partOfSpeech = PartOfSpeech.Adjective;
    this.text = text;
  }
  Word.noun(String text){
    partOfSpeech = PartOfSpeech.Noun;
    this.text = text;
  }
  Word.empty(){
    ;
  }
}
//Just need local prefs to save that premium has been purchased and if starter words need to be added to box
String adjectives = "big,smelly,small,heavy,aggressive,sticky,crazy,slimy,undead,vampiric,camouflaged,flying,fast,alert,angry,annoyed,attractive,cute,one-eyed,brave,smart,cunning,calm,charming,creepy,cruel,curious,dangerous,determined,disgusting,magical,energetic,evil,fierce,harsh,grumpy,healthy,fit,hungry,jittery,tall,short,loving,nasty,naughty,prickly,repulsive,storm-controlling,sword-wielding,gun-wielding,black belt,jetpack-equipped,metallic,parachuting,electrical,flaming,icy,burps frequently,sick,loud,quiet,adaptive,teleporting,amazing eyesight,has an attack dog,venomous,armored";
String nouns = "aardvark,bear,raccoon,mosquito,human,cat,dog,bird,robot,elephant,pirate,astronaut,soldier,demon,werewolf,bodybuilder,rapper";
String blueText = "";

String redText = "";

List<HistoryItem> historyItems = [];

bool hasPremium = false;

List<String> allNouns = [];

List<String> allAdjectives = [];

List<Word> allWords = [];

String sortValue = "0";

final String premiumEditionID = "premium";

Function removeItem = () => {};

Box? prefs;

String getRandomString(List<String> stringList){
  return stringList[Random().nextInt(stringList.length)];
}

String GenerateRandomText(){
  String finalString = "";
  String firstAdjective = "";
  String secondAdjective = "";
  while(firstAdjective == secondAdjective && allAdjectives.length > 1){
    firstAdjective = getRandomString(allAdjectives);
    secondAdjective = getRandomString(allAdjectives);
  }
  if(allAdjectives.length <= 1){
    firstAdjective = getRandomString(allAdjectives);
    secondAdjective = getRandomString(allAdjectives);
  }
  String noun = getRandomString(allNouns);
  firstAdjective = StringUtils.capitalize(firstAdjective);
  secondAdjective = StringUtils.capitalize(secondAdjective);
  noun = StringUtils.capitalize(noun);
  finalString = firstAdjective + ",\n" + secondAdjective + ",\n" + noun;
  return finalString;
}

HistoryItem DecompileText(String text){
  //Text should look like &B&Blue|-|Red  where the first letter in between the ampersands is the winner and the text after that is blue, a split, red.
  return HistoryItem(
    winner: text.contains("&B&") ? Winner.Blue : Winner.Red,
    red: text.substring(3).split('|-|')[1],
    blue: text.substring(3).split('|-|')[0],
  );
}


void main() async {
  await Hive.initFlutter();
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  final bool? first = preferences.getBool('first');
  if(first == null){
    await Hive.deleteFromDisk();
  }
  preferences.setBool('first', true);
  Box history = await Hive.openBox('historyBox');
  Box nounBox = await Hive.openBox('nounBox');
  Box adjectiveBox = await Hive.openBox('adjectiveBox');
  prefs = await Hive.openBox('prefsBox');
  bool start = prefs?.get('start', defaultValue: true);
  hasPremium = prefs?.get('premium', defaultValue: false);
  allNouns = nounBox.values.toList().cast<String>() + (start ? nouns.split(',') : []);
  allNouns = allNouns.toSet().toList();
  allAdjectives = adjectiveBox.values.toList().cast<String>() + (start ? adjectives.split(',') : []);
  allAdjectives = allAdjectives.toSet().toList();
  while(redText == blueText && allAdjectives.length > 1) {
    redText = GenerateRandomText();
    blueText = GenerateRandomText();
  }
  for(int i=0; i < allNouns.length; i++){
    nounBox.put(allNouns[i], allNouns[i]);
  }
  for(int i=0; i < allAdjectives.length; i++){
    adjectiveBox.put(allAdjectives[i], allAdjectives[i]);
  }
  for(int i=0; i < history.length; i++){
    historyItems.add(DecompileText(history.get(i)));
  }
  allWords = [];
  for(int i=0;i<allNouns.length;i++){
    allWords.add(Word.noun(allNouns[i]));
  }
  for(int i=0;i<allAdjectives.length;i++){
    allWords.add(Word.adjective(allAdjectives[i]));
  }
  prefs?.put('start', false);
  runApp(MyApp(history: history, allnouns: nounBox, alladjectives: adjectiveBox,));
}

class MyApp extends StatelessWidget {
  MyApp({Key? key, required this.history, required this.allnouns, required this.alladjectives}) : super(key: key);
  final Box history;
  final Box allnouns;
  final Box alladjectives;
  // This widget is the root of your application.
  @override
  Widget build  (BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color.fromRGBO(200, 207, 242, 1)
      ),
      initialRoute: '/',
      routes: {
        '/':  (context) => MyHomePage(history: this.history,),
        '/history': (context) => HistoryPage(),
        '/add': (context) => AddWordsPage(allnouns: this.allnouns, alladjectives: this.alladjectives),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.history,}) : super(key: key);
  final Box history;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin{

  InAppPurchase _iap = InAppPurchase.instance;
  bool _available = true;
  List<ProductDetails> _products = [];
  List <PurchaseDetails> _purchases = [];
  StreamSubscription? _subscription;
  BuildContext? contextReference;
  bool justRestored = false;
  bool foundPurchase = false;
  @override
  void initState(){
    _initialize();
    super.initState();
    UnityAds.init(
      gameId: '4283505',
      testMode: false,
      onComplete: () => print('Initialization Complete'),
      onFailed: (error, message) => print('Initialization Failed: $error $message'),
    );
  }
  @override
  void dispose(){
    _subscription?.cancel();
    super.dispose();
  }
  void _initialize() async {

    _available = await _iap.isAvailable();
    if(_available){
      _subscription = _iap.purchaseStream.listen((data) => setState(() {
        HandlePurchases(data);
        foundPurchase = true;
      }));
      if(justRestored){
        if(!foundPurchase && hasPremium == false){
          setState(() {
              hasPremium = false;
              prefs?.put('premium', false);
              PopUp('Purchase was Refunded');
          });
        }
        justRestored = false;
        foundPurchase = false;
      }
      List<Future> futures = [_getProducts(), _getPastPurchases()];
      await Future.wait(futures);
    }
  }
  Future<void> _getProducts() async {
    ProductDetailsResponse response = await _iap.queryProductDetails(Set.from([premiumEditionID]));
    if (response.notFoundIDs.isNotEmpty) {
      print("Can't Find ID");
    }
    setState(() {
       _products = response.productDetails;
    });
  }
  Future<void> _getPastPurchases() async {
    //await Future.delayed(const Duration(milliseconds: 1500));
    Box purchaseObject = await Hive.openBox('timeObjects');
    if(purchaseObject.isEmpty || DateTime.now().millisecondsSinceEpoch - purchaseObject.get('Pending') - 300000 >= 0)
    {
      await _iap.restorePurchases(applicationUserName: null);
      if(purchaseObject.containsKey('Pending')){
        purchaseObject.delete('Pending');
      }
      purchaseObject.close();
    }
    justRestored = true;
  }
  void HandlePurchases(List<PurchaseDetails> purchaseDetailsList) async{
    Box purchaseObject = await Hive.openBox('timeObjects');
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
        if (purchaseDetails.status == PurchaseStatus.error) {
          PopUp("Error with Purchase");
        }

        else if (purchaseDetails.status == PurchaseStatus.pending) {
          PopUp("Purchase is Pending. Purchase Completion Will Be Checked in 5 Minutes");
          purchaseObject.put('Pending', DateTime.now().millisecondsSinceEpoch);
          purchaseObject.close();
          if (purchaseDetails.pendingCompletePurchase){
            await _iap.completePurchase(purchaseDetails);
          }
        }

        else if (purchaseDetails.status == PurchaseStatus.purchased) {
          PurchasePremium(true);
          if (purchaseDetails.pendingCompletePurchase) {
            await _iap.completePurchase(purchaseDetails);
          }
        }

        else if(purchaseDetails.status == PurchaseStatus.restored && purchaseDetails.productID == premiumEditionID) {
          PurchasePremium(false);
          if (purchaseDetails.pendingCompletePurchase){
            await _iap.completePurchase(purchaseDetails);
          }
        }
        else if (purchaseDetails.status == PurchaseStatus.canceled) {
          PopUp("Purchase was Cancelled");
        }



    });
  }
  void PurchasePremium(bool firstPurchase) async {
    Box purchaseObject = await Hive.openBox('timeObjects');
    setState(() {
      if(contextReference != null || firstPurchase == false) {
        if(firstPurchase){
          Navigator.pop(contextReference!);
        }
        hasPremium = true;
        prefs?.put('premium', true);
        if(purchaseObject.containsKey('Pending')){
          purchaseObject.delete('Pending');
        }
        purchaseObject.close();
        if(firstPurchase) {
          ScaffoldMessenger.of(contextReference!).showSnackBar(
            SnackBar(
              content: Text(
                "Thank you for your purchase! You now have premium!",
                style: GoogleFonts.raleway(
                ),
              ),
            ),
          );
        }
      }
    });
  }
  void PopUp(String text){
    setState(() {
      if(contextReference != null) {
        Navigator.pop(contextReference!);
        ScaffoldMessenger.of(contextReference!).showSnackBar(
          SnackBar(
            content: Text(
              text,
              style: GoogleFonts.raleway(
              ),
            ),
          ),
        );
      }
    });
  }
  void RegenerateText(Winner winner){
    String winnerText = winner == Winner.Blue ? "&B&" : "&R&";
    widget.history.put(widget.history.length, winnerText + blueText + "|-|" + redText);
    historyItems = [];
    for(int i= 0; i < widget.history.length; i++){
      historyItems.add(DecompileText(widget.history.get(i)));
    }
    redText = "";
    blueText = "";
    while(redText == blueText) {
      setState(() {
        redText = GenerateRandomText();
        blueText = GenerateRandomText();
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    contextReference = context;

    void ShowPurchaseOverlay(){
      _getPastPurchases();
      showDialog(context: context, builder: (BuildContext context) {
        return new SimpleDialog(
          contentPadding: EdgeInsets.fromLTRB(16, 32, 16, 32),
          backgroundColor: Color.fromRGBO(200, 207, 242, 1),
          title: Text(
            "Buy Premium",
            style: GoogleFonts.russoOne(
              textStyle: TextStyle(
                fontSize: 28,
              ),
            ),
            textAlign: TextAlign.center,
          ),
          children: [
            Text(
              "•No Ads\n•Add Custom Words",
              style: GoogleFonts.raleway(
                textStyle: TextStyle(
                  fontSize: 28,
                ),
              ),
              textAlign: TextAlign.center,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                child: Text(
                  "Purchase",
                ),
                onPressed: () => {
                  InAppPurchase.instance.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: _products[0]))
                },
              ),
            ),
          ],
        );
      });
    }
    List<Widget> GetTopRow(){
      if(!hasPremium) {
        return [
          IconButton(
            icon: Icon(
              Icons.attach_money,
              size: 24,
            ),
            onPressed: () => {ShowPurchaseOverlay()},
          ),
          IconButton(
            icon: Icon(
              Icons.history,
              size: 24,
            ),
            onPressed: () => {Navigator.pushNamed(context, '/history')},
          ),
        ];
      }
      else{
        return [
          IconButton(
            icon: Icon(
              Icons.add,
              size: 24,
            ),
            onPressed: () => {Navigator.pushNamed(context, '/add')},
          ),
          IconButton(
            icon: Icon(
              Icons.history,
              size: 24,
            ),
            onPressed: () => {Navigator.pushNamed(context, '/history')},
          ),
        ];
      }
    }
    return Scaffold(
      body: Flex(
        direction:  Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SafeArea(
            child: Row(
                children: GetTopRow(),
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
              ),
          ),
          Flexible(
            child: Flex(
              direction: MediaQuery.of(context).orientation == Orientation.portrait ?  Axis.vertical : Axis.horizontal,
              children: [
                SizedBox(
                  height: 200,
                  width: 350,
                  child: ElevatedButton(
                      onPressed: () => {RegenerateText(Winner.Blue)},
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blue
                      ),
                      child: Text(
                        blueText,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.raleway(
                          textStyle: TextStyle(
                            fontSize: 36
                          )
                        ),
                      ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(0),
                  child: Text(
                    'VS',
                    style: GoogleFonts.russoOne(
                      textStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 36,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 10),
                            blurRadius: 10,
                            color: Color.fromRGBO(0, 0, 0, 0.2)
                          )
                        ]
                      )
                    ),
                  ),
                ),
                SizedBox(
                  height: 200,
                  width: 350,
                  child: ElevatedButton(
                    onPressed: () => {RegenerateText(Winner.Red)},
                    style: ElevatedButton.styleFrom(
                        primary: Colors.red
                    ),
                    child: Text(
                      redText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.raleway(
                          textStyle: TextStyle(
                              fontSize: 36
                          )
                      ),
                    ),
                  ),
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
            ),
            flex: 10,
          ),
          hasPremium ? SizedBox.fromSize(size: Size.fromHeight(MediaQuery.of(context).orientation == Orientation.portrait ? 90 : 30),) : UnityBannerAd(
              placementId: "Banner_Android",
              size: BannerSize.standard,
            ),
        ],
      ),

    );
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => {Navigator.pop(context)},
                  icon: Icon(
                    Icons.arrow_back,
                    size: 24,
                  ),
                ),
                Text(
                  "History",
                  style: GoogleFonts.russoOne(
                    textStyle: TextStyle(
                      fontSize: 20
                    )
                  ),
                )
              ],
            ),
            historyItems.length > 0 ? Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: historyItems.length,
                itemBuilder: (BuildContext context, int index) {
                  return historyItems.reversed.toList()[index];
                }
              ),
            ) : Center(
              child: Text(
                "Nothing here for now. Try choosing the outcome of some battles!",
                textAlign: TextAlign.center,
                style: GoogleFonts.raleway(
                  textStyle: TextStyle(
                    color: Colors.grey
                  )
                ),
              ),
            ),
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
      ),
    );
  }
}

class AddWordsPage extends StatefulWidget {
  AddWordsPage({required this.allnouns, required this.alladjectives});
  final Box allnouns;
  final Box alladjectives;
  @override
  _AddWordsPageState createState() => _AddWordsPageState();
}

class _AddWordsPageState extends State<AddWordsPage> {
  int wordLength = allWords.length;
  final myController = TextEditingController();
  PartOfSpeech currentPartOfSpeech = PartOfSpeech.Noun;
  void SortByAlphabet(){
    setState(() {
      allWords.sort((a, b) => a.text.toLowerCase().compareTo(b.text.toLowerCase()));
    });
  }
  void SortByPartOfSpeech(){
    setState(() {
      allWords.sort((a, b) => (a.partOfSpeech == PartOfSpeech.Noun ? 0 : 1).compareTo( (b.partOfSpeech == PartOfSpeech.Noun ? 0 : 1) )  );
    });

  }
  bool _addItem(PartOfSpeech pos, String text){
    if(PartOfSpeech.Noun == pos ? allNouns.contains(text) : allAdjectives.contains(text)){
      return false;
    }
    allWords.add(Word(pos, text));
    PartOfSpeech.Noun == pos ? allNouns.add(text) : allAdjectives.add(text);
    PartOfSpeech.Noun == pos ? widget.allnouns.put(text, text) : widget.alladjectives.put(text, text);
    setState(() {
      wordLength = wordLength + 1;
    });
    SortByAlphabet();
    return true;
  }
  _removeItem(Word word){
    allWords.remove(word);
    PartOfSpeech.Noun == word.partOfSpeech ? allNouns.remove(word.text) : allAdjectives.remove(word.text);
    PartOfSpeech.Noun == word.partOfSpeech ? widget.allnouns.delete(word.text) : widget.alladjectives.delete(word.text);
    setState(() {
      wordLength = wordLength - 1;
    });
  }
  @override
  Widget build(BuildContext context) {

    void ShowErrorSnackBar(String errorText){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorText,
            style: GoogleFonts.raleway(
            ),
          ),
        ),
      );
    }
    void OpenAddOverlay(){
      showDialog(context: context, builder: (BuildContext context) {
        return new SimpleDialog(
          contentPadding: EdgeInsets.fromLTRB(16, 32, 16, 32),
          backgroundColor: Color.fromRGBO(200, 207, 242, 1),
          title: Text(
            "Add Words",
            style: GoogleFonts.russoOne(
              textStyle: TextStyle(
                fontSize: 28,
              ),
            ),
            textAlign: TextAlign.center,
          ),
          children: [
            DropdownButtonFormField<String>(
              value: sortValue,
              elevation: 16,
              style: GoogleFonts.raleway(color: Colors.black),
              onChanged: ((String? newValue) {
                  sortValue = newValue!;
                  switch (newValue) {
                    case "0":
                      currentPartOfSpeech = PartOfSpeech.Noun;
                      print("0");
                      break;
                    case "1":
                      currentPartOfSpeech = PartOfSpeech.Adjective;
                      print("1");
                      break;
                  }
              }),
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem(
                    value: "0",
                    child: Text(
                      "Noun",
                      style: GoogleFonts.raleway(
                          fontSize: 24
                      ),
                    )
                ),
                DropdownMenuItem(
                    value: "1",
                    child: Text(
                      "Adjective",
                      style: GoogleFonts.raleway(
                          fontSize: 24
                      ),
                    )
                ),
              ],
            ),
            TextField(
              controller: myController,
              keyboardType: TextInputType.text,
              style: GoogleFonts.raleway(color: Colors.black, fontSize: 24),
              decoration: InputDecoration(isDense: true,)..applyDefaults(Theme.of(context).inputDecorationTheme),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                child: Text(
                  "Ok",
                ),
                onPressed: () => {
                  _addItem(currentPartOfSpeech, myController.text) ?  Navigator.pop(context) : ShowErrorSnackBar("Word already exists"),
                  myController.text = "",
                  currentPartOfSpeech = PartOfSpeech.Noun,
                },
              ),
            ),
          ],
        );
      });
    }
    allWords.sort((a, b) => a.text.toLowerCase().compareTo(b.text.toLowerCase()));
    removeItem = _removeItem;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SafeArea(
            child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: () => {Navigator.pop(context)},
                            icon: Icon(
                              Icons.arrow_back,
                              size: 24,
                            ),
                          ),
                          Text(
                            "Add Words",
                            style: GoogleFonts.russoOne(
                              textStyle: TextStyle(
                                fontSize: 20
                              ),
                            ),
                          ),

                        ],
                      ),
                      IconButton(
                        onPressed: () => {OpenAddOverlay()},
                        icon: Icon(
                          Icons.add,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [

                      /*
                      Transform(
                        alignment: Alignment.center,
                          transform: Matrix4.rotationY(pi),
                          child: IconButton(
                              onPressed: () => {OpenFilterOverlay()},
                              icon: Icon(
                                Icons.sort,
                              ),
                          ),
                      )

                       */
                    ],
                  ),
                  SizedBox(
                    height: ((MediaQuery.of(context).size.height)) - 100,
                    width: 700,
                    child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: this.wordLength,
                        itemBuilder: (BuildContext context, int index) => this._buildWordCard(index)
                    ),
                  )
                ]
              )
            ),

        ],
      )
      );
    }
    _buildWordCard(int index){
      return WordItem(allWords[index]);
    }
}

class HistoryItem extends StatelessWidget {

  final Winner? winner;
  final String red;
  final String blue;

  const HistoryItem({Key? key,  this.winner, this.red = "", this.blue = ""}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                height: this.winner == Winner.Blue ? 105 : 90,
                width: this.winner == Winner.Blue ? 155 : 140,
                child: Card(
                  color: Colors.blue,
                  child: Center(
                    child: Text(
                      this.blue,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.raleway(
                        textStyle: TextStyle(
                            fontSize: this.winner == Winner.Blue ? 17 : 16,
                          color: Colors.white
                        )
                      ),
                    ),
                  ),
                ),
              ),
              this.winner == Winner.Blue ? Positioned(
                child: SizedBox(
                  width: 45,
                  height: 45,
                  child: Transform(
                    transform: Matrix4.rotationZ(-0.8),
                    child: SvgPicture.asset(
                        "assets\\VectorCrown.svg"
                      ),
                  ),
                  ),
                right: 135,
                bottom: 50,
                ) : Container(),
            ]
          ),
          Padding(
            padding: const EdgeInsets.all(0),
            child: Text(
              'VS',
              style: GoogleFonts.russoOne(
                  textStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      shadows: [
                        Shadow(
                            offset: Offset(0, 10),
                            blurRadius: 10,
                            color: Color.fromRGBO(0, 0, 0, 0.2)
                        )
                      ]
                  )
              ),
            ),
          ),
          Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  height: this.winner == Winner.Red ? 105 : 90,
                  width: this.winner == Winner.Red ? 155 : 140,
                  child: Card(
                    color: Colors.red,
                    child: Center(
                      child: Text(
                        this.red,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.raleway(
                            textStyle: TextStyle(
                                fontSize: this.winner == Winner.Red ? 17 : 16,
                                color: Colors.white
                            )
                        ),
                      ),
                    ),
                  ),
                ),
                this.winner == Winner.Red ? Positioned(
                  child: SizedBox(
                    width: 45,
                    height: 45,
                    child: Transform(
                      transform: Matrix4.rotationZ(0.8),
                      child: SvgPicture.asset(
                          "assets\\VectorCrown.svg"
                      ),
                    ),
                  ),
                  left: 150,
                  bottom: 85,
                ) : Container(),
              ]
          ),
        ],
      ),
    );
  }
}

class WordItem extends StatelessWidget {
  const WordItem(this.word);
  final Word word;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, 16, 8, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  (word.partOfSpeech == PartOfSpeech.Noun ? "Noun :   " : "Adjective :   "),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.raleway(
                    fontSize: 16,
                  ),
                ),
                Text(
                  word.text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.raleway(
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            IconButton(
                onPressed: () => {removeItem(word)},
                icon: Icon(
                  Icons.delete,
                  size: 24,
                ),
            )
          ],
        ),
      ),
    );
  }
}


