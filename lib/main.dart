import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';

void main()=>runApp(const CallAPK());

class CallAPK extends StatelessWidget{
  const CallAPK({super.key});
  Widget build(BuildContext c)=>MaterialApp(
    debugShowCheckedModeBanner:false,title:'CallAPK',
    theme:ThemeData(useMaterial3:true,colorSchemeSeed:Colors.blue),
    home:const CallHomePage());
}

class Client{
  String name,mobile,work,place,charges,parts,remark,status;
  DateTime callDate; DateTime? closeDate;
  Client({required this.name,required this.mobile,required this.work,required this.place,
    required this.charges,required this.parts,required this.remark,required this.status,
    required this.callDate,this.closeDate});
  Map<String,dynamic> toJson()=>{'name':name,'mobile':mobile,'work':work,'place':place,
    'charges':charges,'parts':parts,'remark':remark,'status':status,
    'callDate':callDate.toIso8601String(),'closeDate':closeDate?.toIso8601String()};
  factory Client.fromJson(Map<String,dynamic> j)=>Client(
    name:j['name']??'',mobile:j['mobile']??'',work:j['work']??'',place:j['place']??'',
    charges:j['charges']??'',parts:j['parts']??'',remark:j['remark']??'',
    status:j['status']??'Open',callDate:DateTime.tryParse(j['callDate']??'')??DateTime.now(),
    closeDate:j['closeDate']==null?null:DateTime.tryParse(j['closeDate']));
}

class CallHomePage extends StatefulWidget{
  const CallHomePage({super.key});
  State<CallHomePage> createState()=>_CallHomePageState();
}

class _CallHomePageState extends State<CallHomePage>{
  static const key='callapk_clients_final';
  final List<Client> clients=[]; String filter='All'; bool loading=true;

  void initState(){super.initState();loadData();}
  Future<void> loadData() async{
    final p=await SharedPreferences.getInstance(), raw=p.getString(key);
    if(raw!=null){try{
      clients.addAll((jsonDecode(raw) as List).map((e)=>Client.fromJson(Map<String,dynamic>.from(e))));
    }catch(_){}} if(mounted)setState(()=>loading=false);
  }
  Future<void> saveData() async{
    final p=await SharedPreferences.getInstance();
    await p.setString(key,jsonEncode(clients.map((e)=>e.toJson()).toList()));
  }
  String dt(DateTime d)=>'${d.day.toString().padLeft(2,'0')}-${d.month.toString().padLeft(2,'0')}-${d.year}';
  String tm(DateTime d)=>'${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';

  Future<void> whatsapp(Client c) async{
    final n=c.mobile.replaceAll(RegExp(r'[^0-9]'),'');
    final phone=n.startsWith('91')?n:'91$n';
    final closed=c.closeDate==null?'Not closed':'${dt(c.closeDate!)} ${tm(c.closeDate!)}';
    final message=[
      'Saini Info Solutions','',
      'Dear ${c.name},','',
      'Aapki service call ki details:','',
      'Call Date: ${dt(c.callDate)}','Kaam: ${c.work}',
      'Place: ${c.place}','Charges: Rs. ${c.charges}',
      'Parts: ${c.parts.isEmpty?'Koi nahi':c.parts}','Status: ${c.status}',
      'Call Close: $closed','Mobile No.: ${c.mobile}','',
      'Thank you,','Saini Info Solutions'
    ].join('\n');
    final u=Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
    if(await canLaunchUrl(u)){await launchUrl(u,mode:LaunchMode.externalApplication);}
  }

  Future<void> makePdf(Client c) async{
    final pdf=pw.Document();
    pdf.addPage(pw.Page(pageFormat:PdfPageFormat.a4,build:(x)=>pw.Padding(
      padding:const pw.EdgeInsets.all(24),child:pw.Column(
      crossAxisAlignment:pw.CrossAxisAlignment.start,children:[
        pw.Text('SAINI INFO SOLUTIONS',style:pw.TextStyle(fontSize:22,fontWeight:pw.FontWeight.bold)),
        pw.SizedBox(height:8),pw.Text('SERVICE CALL REPORT',style:pw.TextStyle(fontSize:16,fontWeight:pw.FontWeight.bold)),
        pw.Divider(),pw.SizedBox(height:10),
        pw.Text('Client Name: ${c.name}'),pw.Text('Mobile No.: ${c.mobile}'),
        pw.Text('Kaam / Complaint: ${c.work}'),pw.Text('Place / Address: ${c.place}'),
        pw.Text('Charges: Rs. ${c.charges}'),pw.Text('Parts Details: ${c.parts.isEmpty?'Koi nahi':c.parts}'),
        pw.Text('Status: ${c.status}'),pw.Text('Call Date: ${dt(c.callDate)}'),
        pw.Text('Call Close: ${c.closeDate==null?'Not closed':'${dt(c.closeDate!)} ${tm(c.closeDate!)}'}'),
        pw.Text('Remark: ${c.remark}'),pw.SizedBox(height:30),
        pw.Text('Thank you - Saini Info Solutions')
      ]))));
    final dir=await getTemporaryDirectory();
    final f=File('${dir.path}/Call_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await f.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(f.path)],text:'Service Call Report - ${c.name}');
  }

  Future<void> add() async{final r=await form();if(r!=null){setState(()=>clients.insert(0,r));await saveData();}}
  Future<void> edit(Client c) async{await form(existing:c);setState((){});await saveData();}

  Future<Client?> form({Client? existing}) async{
    final n=TextEditingController(text:existing?.name??''),m=TextEditingController(text:existing?.mobile??''),
    w=TextEditingController(text:existing?.work??''),p=TextEditingController(text:existing?.place??''),
    ch=TextEditingController(text:existing?.charges??''),pa=TextEditingController(text:existing?.parts??''),
    r=TextEditingController(text:existing?.remark??''); String status=existing?.status??'Open';
    final result=await showDialog<Client>(context:context,builder:(_)=>StatefulBuilder(
      builder:(c,setD)=>AlertDialog(title:Text(existing==null?'Client Add':'Edit Call'),
      content:SingleChildScrollView(child:Column(children:[
        fld(n,'Client Name'),fld(m,'Mobile No.',TextInputType.phone),fld(w,'Kaam / Complaint'),
        fld(p,'Place / Address'),fld(ch,'Charges',TextInputType.number),fld(pa,'Parts Details'),
        fld(r,'Remark / Extra Details'),DropdownButtonFormField<String>(value:status,
        decoration:const InputDecoration(labelText:'Call Status'),items:const[
          DropdownMenuItem(value:'Open',child:Text('Open')),DropdownMenuItem(value:'Pending',child:Text('Pending')),
          DropdownMenuItem(value:'Closed',child:Text('Closed'))],
        onChanged:(v)=>setD(()=>status=v??status))
      ])),actions:[
        TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Cancel')),
        FilledButton(onPressed:(){
          if(n.text.trim().isEmpty||m.text.trim().isEmpty)return; final now=DateTime.now();
          if(existing!=null){
            existing..name=n.text.trim()..mobile=m.text.trim()..work=w.text.trim()..place=p.text.trim()
            ..charges=ch.text.trim()..parts=pa.text.trim()..remark=r.text.trim()..status=status
            ..closeDate=status=='Closed'?(existing.closeDate??now):null; Navigator.pop(c,existing);
          }else{Navigator.pop(c,Client(name:n.text.trim(),mobile:m.text.trim(),work:w.text.trim(),place:p.text.trim(),
            charges:ch.text.trim(),parts:pa.text.trim(),remark:r.text.trim(),status:status,callDate:now,
            closeDate:status=='Closed'?now:null));}
        },child:const Text('Save'))
      ])));
    for(final x in[n,m,w,p,ch,pa,r])x.dispose(); return result;
  }

  Widget fld(TextEditingController c,String label,[TextInputType t=TextInputType.text])=>Padding(
    padding:const EdgeInsets.only(bottom:8),child:TextField(controller:c,keyboardType:t,
    decoration:InputDecoration(labelText:label,border:const OutlineInputBorder())));

  Widget build(BuildContext context){
    final list=clients.where((c)=>filter=='All'||c.status==filter).toList();
    return Scaffold(appBar:AppBar(title:const Text('CallAPK'),actions:[PopupMenuButton<String>(
      onSelected:(v)=>setState(()=>filter=v),itemBuilder:(_)=>const[
        PopupMenuItem(value:'All',child:Text('All Calls')),PopupMenuItem(value:'Open',child:Text('Open')),
        PopupMenuItem(value:'Pending',child:Text('Pending')),PopupMenuItem(value:'Closed',child:Text('Closed'))])]),
      body:loading?const Center(child:CircularProgressIndicator()):
      list.isEmpty?const Center(child:Text('Abhi koi call nahi hai')):
      ListView.builder(padding:const EdgeInsets.all(10),itemCount:list.length,itemBuilder:(_,i){
        final c=list[i];return Card(child:ListTile(title:Text(c.name,style:const TextStyle(fontWeight:FontWeight.bold)),
          subtitle:Text('${c.mobile}\n${c.work}\n${c.place}\nStatus: ${c.status}'),isThreeLine:true,
          onTap:()=>edit(c),trailing:Wrap(children:[
            IconButton(tooltip:'WhatsApp',icon:const Icon(Icons.message,color:Colors.green),onPressed:()=>whatsapp(c)),
            IconButton(tooltip:'PDF',icon:const Icon(Icons.picture_as_pdf,color:Colors.red),onPressed:()=>makePdf(c))
          ]))));}),
      floatingActionButton:FloatingActionButton.extended(onPressed:add,icon:const Icon(Icons.person_add),label:const Text('Client Add')));
  }
}
