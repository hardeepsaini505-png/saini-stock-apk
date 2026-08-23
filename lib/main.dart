
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
  @override
  Widget build(BuildContext c)=>MaterialApp(
    debugShowCheckedModeBanner:false,
    title:'CallAPK',
    theme:ThemeData(useMaterial3:true,colorSchemeSeed:Colors.blue),
    home:const CallHomePage());
}

class Client{
  String jobNo,name,mobile,work,place,charges,parts,remark,status;
  DateTime callDate; DateTime? closeDate;
  Client({required this.jobNo,required this.name,required this.mobile,required this.work,
    required this.place,required this.charges,required this.parts,required this.remark,
    required this.status,required this.callDate,this.closeDate});
  Map<String,dynamic> toJson()=>{'jobNo':jobNo,'name':name,'mobile':mobile,'work':work,'place':place,
    'charges':charges,'parts':parts,'remark':remark,'status':status,
    'callDate':callDate.toIso8601String(),'closeDate':closeDate?.toIso8601String()};
  factory Client.fromJson(Map<String,dynamic> j)=>Client(
    jobNo:j['jobNo']??'',name:j['name']??'',mobile:j['mobile']??'',work:j['work']??'',
    place:j['place']??'',charges:j['charges']??'',parts:j['parts']??'',remark:j['remark']??'',
    status:j['status']??'Open',
    callDate:DateTime.tryParse(j['callDate']??'')??DateTime.now(),
    closeDate:j['closeDate']==null?null:DateTime.tryParse(j['closeDate']));
}

class _PartRow{
  final name=TextEditingController();
  final qty=TextEditingController(text:'1');
  final rate=TextEditingController();
  final total=TextEditingController(text:'0');
  _PartRow({String n='',String q='1',String r='',String t='0'}){
    name.text=n; qty.text=q; rate.text=r; total.text=t;
  }
  void calc(){
    final q=double.tryParse(qty.text.trim())??0;
    final r=double.tryParse(rate.text.trim())??0;
    total.text=(q*r).toStringAsFixed(2);
  }
  void dispose(){name.dispose();qty.dispose();rate.dispose();total.dispose();}
}

class CallHomePage extends StatefulWidget{
  const CallHomePage({super.key});
  @override
  State<CallHomePage> createState()=>_CallHomePageState();
}

class _CallHomePageState extends State<CallHomePage>{
  static const key='callapk_clients_final_v3';
  static const settingsKey='callapk_firm_settings_v3';
  final List<Client> clients=[];
  String filter='All';
  bool loading=true;
  String firmName='Saini Info Solutions',firmAddress='',firmPhone='',jobPrefix='';
  int nextJobNo=1;
  bool watermarkEnabled=true;

  // Hidden watermark control: tap the side watermark 7 times, then enter the private PIN.
  // Change this PIN in this source before sharing the APK.
  static const String _watermarkPin='7391';

  @override
  void initState(){super.initState();loadData();}

  Future<void> loadData() async{
    final sp=await SharedPreferences.getInstance();
    final settings=sp.getString(settingsKey);
    if(settings!=null){
      try{
        final j=Map<String,dynamic>.from(jsonDecode(settings));
        firmName=(j['firmName']??'Saini Info Solutions').toString();
        firmAddress=(j['firmAddress']??'').toString();
        firmPhone=(j['firmPhone']??'').toString();
        jobPrefix=(j['jobPrefix']??'').toString();
        nextJobNo=int.tryParse('${j['nextJobNo']??1}')??1;
        watermarkEnabled=j['watermarkEnabled']!=false;
      }catch(_){}
    }
    final raw=sp.getString(key);
    if(raw!=null){
      try{
        final list=jsonDecode(raw) as List;
        int maxNo=0;
        for(final e in list){
          final c=Client.fromJson(Map<String,dynamic>.from(e));
          if(c.jobNo.isEmpty){
            c.jobNo='$jobPrefix${maxNo+1}';
          }
          final match=RegExp(r'(\d+)$').firstMatch(c.jobNo);
          if(match!=null){
            final no=int.tryParse(match.group(1)!)??0;
            if(no>maxNo)maxNo=no;
          }
          clients.add(c);
        }
        if(nextJobNo<=maxNo)nextJobNo=maxNo+1;
      }catch(_){}
    }
    await saveSettings();
    if(mounted)setState(()=>loading=false);
  }

  Future<void> saveSettings() async{
    final sp=await SharedPreferences.getInstance();
    await sp.setString(settingsKey,jsonEncode({
      'firmName':firmName,'firmAddress':firmAddress,'firmPhone':firmPhone,
      'jobPrefix':jobPrefix,'nextJobNo':nextJobNo,'watermarkEnabled':watermarkEnabled
    }));
  }

  Future<void> saveData() async{
    final sp=await SharedPreferences.getInstance();
    await sp.setString(key,jsonEncode(clients.map((e)=>e.toJson()).toList()));
  }

  String dt(DateTime d)=>'${d.day.toString().padLeft(2,'0')}-${d.month.toString().padLeft(2,'0')}-${d.year}';
  String tm(DateTime d)=>'${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';

  String _newJobNo()=>'$jobPrefix$nextJobNo';

  Future<void> whatsapp(Client c) async{
    final n=c.mobile.replaceAll(RegExp(r'[^0-9]'),'');
    final phone=n.startsWith('91')?n:'91$n';
    final closed=c.closeDate==null?'Not closed':'${dt(c.closeDate!)} ${tm(c.closeDate!)}';
    final message=[
      firmName,
      if(firmAddress.isNotEmpty)firmAddress,
      if(firmPhone.isNotEmpty)'Phone: $firmPhone',
      '',
      'Job Card No.: ${c.jobNo}',
      'Dear ${c.name},',
      '',
      'Aapki service call ki details:',
      '',
      'Call Date: ${dt(c.callDate)}',
      'Kaam: ${c.work}',
      'Place: ${c.place}',
      'Charges: Rs. ${c.charges}',
      'Parts: ${c.parts.isEmpty?'Koi nahi':c.parts}',
      'Status: ${c.status}',
      'Call Close: $closed',
      'Mobile No.: ${c.mobile}',
      'Remark: ${c.remark.isEmpty?'Koi nahi':c.remark}',
      '',
      'Thank you,',
      firmName
    ].join('\n');
    final u=Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
    if(await canLaunchUrl(u))await launchUrl(u,mode:LaunchMode.externalApplication);
  }

  Future<File> _createPdfFile(Client c) async{
    final pdf=pw.Document();
    final base=pw.TextStyle(fontSize:10);
    final bold=pw.TextStyle(fontSize:10,fontWeight:pw.FontWeight.bold);
    final header=pw.TextStyle(fontSize:22,fontWeight:pw.FontWeight.bold);
    final accent=pw.TextStyle(fontSize:13,fontWeight:pw.FontWeight.bold);

    final partRows=<pw.TableRow>[];
    double partsTotal=0;
    if(c.parts.trim().isNotEmpty){
      for(final line in c.parts.split('\n')){
        final p=line.split('|');
        if(p.length>=4){
          final t=double.tryParse(p[3])??0;
          partsTotal+=t;
          partRows.add(pw.TableRow(children:[
            pw.Padding(padding:const pw.EdgeInsets.all(7),child:pw.Text(p[0],style:base)),
            pw.Padding(padding:const pw.EdgeInsets.all(7),child:pw.Text(p[1],style:base)),
            pw.Padding(padding:const pw.EdgeInsets.all(7),child:pw.Text('Rs. ${p[2]}',style:base)),
            pw.Padding(padding:const pw.EdgeInsets.all(7),child:pw.Text('Rs. ${p[3]}',style:base)),
          ]));
        }
      }
    }
    final charges=double.tryParse(c.charges.replaceAll(',',''))??0;
    final grandTotal=charges+partsTotal;

    final pdf=pw.Document();
    pdf.addPage(pw.Page(
      pageFormat:PdfPageFormat.a4,
      margin:const pw.EdgeInsets.all(28),
      build:(context)=>pw.Column(
        crossAxisAlignment:pw.CrossAxisAlignment.start,
        children:[
          pw.Row(
            mainAxisAlignment:pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment:pw.CrossAxisAlignment.start,
            children:[
              pw.Expanded(child:pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[
                pw.Text(firmName,style:header),
                if(firmAddress.isNotEmpty)pw.Padding(
                  padding:const pw.EdgeInsets.only(top:4),
                  child:pw.Text(firmAddress,style:base)),
                if(firmPhone.isNotEmpty)pw.Text('Phone: $firmPhone',style:base),
              ])),
              pw.Container(
                padding:const pw.EdgeInsets.symmetric(horizontal:12,vertical:8),
                decoration:pw.BoxDecoration(border:pw.Border.all(width:1)),
                child:pw.Column(children:[
                  pw.Text('JOB CARD',style:bold),
                  pw.SizedBox(height:3),
                  pw.Text(c.jobNo,style:accent),
                ]))
            ]),
          pw.SizedBox(height:14),
          pw.Container(
            width:double.infinity,
            padding:const pw.EdgeInsets.symmetric(vertical:9,horizontal:12),
            decoration:pw.BoxDecoration(
              color:PdfColors.grey300,
              border:pw.Border.all(width:.5)),
            child:pw.Text('SERVICE CALL REPORT',style:pw.TextStyle(fontSize:14,fontWeight:pw.FontWeight.bold))),
          pw.SizedBox(height:12),
          pw.Table(
            border:pw.TableBorder.all(color:PdfColors.grey500,width:.5),
            columnWidths:{0:const pw.FlexColumnWidth(1),1:const pw.FlexColumnWidth(2)},
            children:[
              _pdfInfoRow('Client Name',c.name),
              _pdfInfoRow('Mobile No.',c.mobile),
              _pdfInfoRow('Kaam / Complaint',c.work),
              _pdfInfoRow('Place / Address',c.place),
              _pdfInfoRow('Call Date',dt(c.callDate)),
              _pdfInfoRow('Status',c.status),
            ]),
          pw.SizedBox(height:16),
          pw.Text('PARTS / MATERIAL',style:accent),
          pw.SizedBox(height:6),
          if(partRows.isNotEmpty)pw.Table(
            border:pw.TableBorder.all(color:PdfColors.grey500,width:.5),
            columnWidths:{0:const pw.FlexColumnWidth(3),1:const pw.FlexColumnWidth(1),2:const pw.FlexColumnWidth(1.5),3:const pw.FlexColumnWidth(1.7)},
            children:[
              pw.TableRow(
                decoration:const pw.BoxDecoration(color:PdfColors.grey300),
                children:[
                  pw.Padding(padding:const pw.EdgeInsets.all(7),child:pw.Text('Part',style:bold)),
                  pw.Padding(padding:const pw.EdgeInsets.all(7),child:pw.Text('Qty',style:bold)),
                  pw.Padding(padding:const pw.EdgeInsets.all(7),child:pw.Text('Rate',style:bold)),
                  pw.Padding(padding:const pw.EdgeInsets.all(7),child:pw.Text('Amount',style:bold)),
                ]),
              ...partRows,
              pw.TableRow(children:[
                pw.Container(),pw.Container(),pw.Padding(
                  padding:const pw.EdgeInsets.all(7),child:pw.Text('Parts Total',style:bold)),
                pw.Padding(padding:const pw.EdgeInsets.all(7),child:pw.Text('Rs. ${partsTotal.toStringAsFixed(2)}',style:bold)),
              ])
            ])
          else pw.Text('No parts added.',style:base),
          pw.SizedBox(height:14),
          pw.Align(alignment:pw.Alignment.centerRight,child:pw.Container(
            width:220,
            padding:const pw.EdgeInsets.all(10),
            decoration:pw.BoxDecoration(border:pw.Border.all(width:1)),
            child:pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.end,children:[
              pw.Text('Service Charges: Rs. ${charges.toStringAsFixed(2)}',style:base),
              pw.SizedBox(height:4),
              pw.Text('Parts Total: Rs. ${partsTotal.toStringAsFixed(2)}',style:base),
              pw.Divider(),
              pw.Text('Grand Total: Rs. ${grandTotal.toStringAsFixed(2)}',
                style:pw.TextStyle(fontSize:13,fontWeight:pw.FontWeight.bold)),
            ]))),
          pw.SizedBox(height:16),
          pw.Text('REMARK',style:accent),
          pw.Container(
            width:double.infinity,
            margin:const pw.EdgeInsets.only(top:5),
            padding:const pw.EdgeInsets.all(10),
            decoration:pw.BoxDecoration(border:pw.Border.all(width:.5)),
            child:pw.Text(c.remark.isEmpty?'No remark':c.remark,style:base)),
          pw.Spacer(),
          pw.Divider(),
          pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween,children:[
            pw.Text('Call Close: ${c.closeDate==null?'Not closed':'${dt(c.closeDate!)} ${tm(c.closeDate!)}'}',style:base),
            pw.Text('Thank you - $firmName',style:bold),
          ])
        ]));

    final dir=await getApplicationDocumentsDirectory();
    final safeName=c.jobNo.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'),'_');
    final f=File('${dir.path}/JobCard_${safeName}.pdf');
    await f.writeAsBytes(await pdf.save(),flush:true);
    return f;
  }

  pw.TableRow _pdfInfoRow(String label,String value)=>pw.TableRow(children:[
    pw.Padding(padding:const pw.EdgeInsets.all(7),child:pw.Text(label,style:pw.TextStyle(fontWeight:pw.FontWeight.bold,fontSize:10))),
    pw.Padding(padding:const pw.EdgeInsets.all(7),child:pw.Text(value.isEmpty?'-':value,style:const pw.TextStyle(fontSize:10))),
  ]);

  Future<void> makePdf(Client c) async{
    final f=await _createPdfFile(c);
    if(!mounted)return;
    await Share.shareXFiles([XFile(f.path)],text:'Job Card ${c.jobNo} - ${c.name}');
  }

  Future<void> downloadPdf(Client c) async{
    final f=await _createPdfFile(c);
    if(!mounted)return;
    await Share.shareXFiles([XFile(f.path)],text:'PDF ready: Job Card ${c.jobNo}');
    if(mounted)ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content:Text('PDF ready: ${f.path}')));
  }

  List<pw.Widget> _pdfParts(String data){
    if(data.trim().isEmpty)return [pw.Text('Koi nahi')];
    return data.split('\n').map((line){
      final p=line.split('|');
      if(p.length>=4)return pw.Text('${p[0]} | Qty: ${p[1]} | Rate: Rs. ${p[2]} | Total: Rs. ${p[3]}');
      return pw.Text(line);
    }).toList();
  }

Future<void> firmSettings() async{
    final n=TextEditingController(text:firmName);
    final a=TextEditingController(text:firmAddress);
    final ph=TextEditingController(text:firmPhone);
    final pre=TextEditingController(text:jobPrefix);
    final result=await showDialog<bool>(
      context:context,
      builder:(ctx)=>AlertDialog(
        title:const Text('Firm / Job Card Settings'),
        content:SingleChildScrollView(child:Column(children:[
          fld(n,'Firm Name'),
          fld(a,'Address'),
          fld(ph,'Phone No.',TextInputType.phone),
          fld(pre,'Job Card Prefix (GST, GST-, etc.)'),
          const Align(alignment:Alignment.centerLeft,child:Padding(
            padding:EdgeInsets.only(top:6),
            child:Text('Example: Prefix GST- rakhenge to GST-1, GST-2, GST-3...'),
          )),
        ])),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),
          FilledButton(onPressed:(){
            firmName=n.text.trim().isEmpty?'Saini Info Solutions':n.text.trim();
            firmAddress=a.text.trim();firmPhone=ph.text.trim();jobPrefix=pre.text.trim();
            Navigator.pop(ctx,true);
          },child:const Text('Save'))
        ]));
    n.dispose();a.dispose();ph.dispose();pre.dispose();
    if(result==true){await saveSettings();if(mounted)setState((){});}
  }

  Future<void> watermarkControl() async{
    int taps=0;
    await showDialog<void>(
      context:context,
      barrierDismissible:true,
      builder:(ctx)=>StatefulBuilder(
        builder:(ctx,setD)=>GestureDetector(
          onTap:(){
            taps++;
            setD((){});
            if(taps>=7){
              Navigator.pop(ctx);
              _askWatermarkPin();
            }
          },
          child:AlertDialog(
            title:const Text('Watermark'),
            content:Text('Is screen par 7 baar tap karein.\nProgress: $taps / 7'),
            actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Close'))],
          ))));
  }

  Future<void> _askWatermarkPin() async{
    final pin=TextEditingController();
    final ok=await showDialog<bool>(
      context:context,
      builder:(ctx)=>AlertDialog(
        title:const Text('Private Watermark Control'),
        content:TextField(controller:pin,obscureText:true,keyboardType:TextInputType.number,
          decoration:const InputDecoration(labelText:'Private PIN')),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),
          FilledButton(onPressed:()=>Navigator.pop(ctx,pin.text==_watermarkPin),child:const Text('Verify'))
        ]));
    final entered=pin.text; pin.dispose();
    if(ok==true && entered==_watermarkPin){
      final newValue=!watermarkEnabled;
      setState(()=>watermarkEnabled=newValue);
      await saveSettings();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text(newValue?'Watermark ON':'Watermark OFF')));
    }else if(ok==true && mounted){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Wrong PIN')));
    }
  }

  Future<String?> partsDialog(String initial) async{
    final rows=<_PartRow>[];
    if(initial.trim().isNotEmpty){
      for(final line in initial.split('\n')){
        final p=line.split('|');
        if(p.length>=4)rows.add(_PartRow(n:p[0],q:p[1],r:p[2],t:p[3]));
      }
    }
    if(rows.isEmpty)rows.add(_PartRow());

    void recalc(_PartRow r){
      final q=double.tryParse(r.qty.text.trim().replaceAll(',',''))??0;
      final rate=double.tryParse(r.rate.text.trim().replaceAll(',',''))??0;
      r.total.text=(q*rate).toStringAsFixed(2);
    }

    final result=await showDialog<String>(
      context:context,
      builder:(ctx)=>StatefulBuilder(
        builder:(ctx,setD)=>AlertDialog(
          title:const Text('Parts Entry'),
          content:SizedBox(
            width:double.maxFinite,
            height:470,
            child:Column(children:[
              Container(
                padding:const EdgeInsets.symmetric(horizontal:8,vertical:6),
                decoration:BoxDecoration(
                  color:Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius:BorderRadius.circular(8)),
                child:const Row(children:[
                  Expanded(flex:4,child:Text('Part Name',style:TextStyle(fontWeight:FontWeight.bold))),
                  SizedBox(width:6),
                  Expanded(flex:2,child:Text('Qty',style:TextStyle(fontWeight:FontWeight.bold))),
                  SizedBox(width:6),
                  Expanded(flex:2,child:Text('Rate',style:TextStyle(fontWeight:FontWeight.bold))),
                  SizedBox(width:3),
                  Expanded(flex:2,child:Text('Amount',style:TextStyle(fontWeight:FontWeight.bold))),
                ])),
              const SizedBox(height:6),
              Expanded(child:ListView.builder(
                itemCount:rows.length,
                itemBuilder:(_,i){
                  final r=rows[i];
                  recalc(r);
                  return Card(
                    margin:const EdgeInsets.only(bottom:7),
                    child:Padding(
                      padding:const EdgeInsets.all(7),
                      child:Row(children:[
                        Expanded(flex:4,child:TextField(
                          controller:r.name,
                          decoration:const InputDecoration(
                            labelText:'Part Name',isDense:true,border:OutlineInputBorder()))),
                        const SizedBox(width:5),
                        Expanded(flex:2,child:TextField(
                          controller:r.qty,
                          keyboardType:const TextInputType.numberWithOptions(decimal:true),
                          decoration:const InputDecoration(
                            labelText:'Qty',isDense:true,border:OutlineInputBorder()),
                          onChanged:(_){recalc(r);setD((){});})),
                        const SizedBox(width:5),
                        Expanded(flex:2,child:TextField(
                          controller:r.rate,
                          keyboardType:const TextInputType.numberWithOptions(decimal:true),
                          decoration:const InputDecoration(
                            labelText:'Rate',isDense:true,border:OutlineInputBorder()),
                          onChanged:(_){recalc(r);setD((){});})),
                        const SizedBox(width:5),
                        Expanded(flex:2,child:TextField(
                          controller:r.total,
                          readOnly:true,
                          decoration:const InputDecoration(
                            labelText:'Amount',isDense:true,border:OutlineInputBorder()),
                        )),
                        IconButton(
                          tooltip:'Delete Part',
                          icon:const Icon(Icons.delete_outline,color:Colors.red),
                          onPressed:rows.length==1?null:(){r.dispose();rows.removeAt(i);setD((){});}),
                      ])));
                })),
              const SizedBox(height:8),
              Builder(builder:(_){
                double grand=0;
                for(final r in rows){
                  recalc(r);
                  grand+=double.tryParse(r.total.text.trim())??0;
                }
                return Container(
                  width:double.infinity,
                  padding:const EdgeInsets.symmetric(horizontal:14,vertical:12),
                  decoration:BoxDecoration(
                    border:Border.all(width:1.2,color:Theme.of(context).colorScheme.primary),
                    borderRadius:BorderRadius.circular(10)),
                  child:Row(
                    mainAxisAlignment:MainAxisAlignment.spaceBetween,
                    children:[
                      const Text('PARTS GRAND TOTAL',
                        style:TextStyle(fontWeight:FontWeight.bold,fontSize:15)),
                      Text('₹ ${grand.toStringAsFixed(2)}',
                        style:TextStyle(fontWeight:FontWeight.bold,fontSize:18,
                          color:Theme.of(context).colorScheme.primary)),
                    ]));
              }),
            ])),
          actions:[
            TextButton(onPressed:(){rows.add(_PartRow());setD((){});},child:const Text('+ Add Part')),
            TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),
            FilledButton(onPressed:(){
              for(final r in rows)recalc(r);
              final data=rows.where((r)=>r.name.text.trim().isNotEmpty)
                .map((r)=>'${r.name.text.trim()}|${r.qty.text.trim()}|${r.rate.text.trim()}|${r.total.text.trim()}')
                .join('\n');
              Navigator.pop(ctx,data);
            },child:const Text('Done'))
          ])));
    for(final r in rows)r.dispose();
    return result;
  }

  Future<void> add() async{
    final r=await form();
    if(r!=null){
      setState(()=>clients.insert(0,r));
      nextJobNo++;
      await saveSettings();
      await saveData();
    }
  }

  Future<void> edit(Client c) async{
    await form(existing:c);
    setState((){});
    await saveData();
  }

  Future<void> deleteClient(Client c) async{
    final yes=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('Delete Client?'),
      content:Text('${c.name} ka Job Card ${c.jobNo} delete karna hai?'),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),
        FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Delete'))
      ]));
    if(yes==true){
      setState(()=>clients.remove(c));
      await saveData();
    }
  }

  Future<Client?> form({Client? existing}) async{
    final job=TextEditingController(text:existing?.jobNo??_newJobNo());
    final n=TextEditingController(text:existing?.name??'');
    final m=TextEditingController(text:existing?.mobile??'');
    final w=TextEditingController(text:existing?.work??'');
    final p=TextEditingController(text:existing?.place??'');
    final ch=TextEditingController(text:existing?.charges??'');
    final pa=TextEditingController(text:existing?.parts??'');
    final r=TextEditingController(text:existing?.remark??'');
    String status=existing?.status??'Open';

    final result=await showDialog<Client>(
      context:context,
      builder:(_)=>StatefulBuilder(
        builder:(c,setD)=>AlertDialog(
          title:Text(existing==null?'Client Add':'Edit Call'),
          content:SingleChildScrollView(child:Column(children:[
            fld(job,'Job Card No. (Manual bhi change kar sakte hain)'),
            fld(n,'Client Name'),
            fld(m,'Mobile No.',TextInputType.phone),
            fld(w,'Kaam / Complaint'),
            fld(p,'Place / Address'),
            fld(ch,'Service Charges',TextInputType.number),
            OutlinedButton.icon(
              icon:const Icon(Icons.build),
              label:Text(pa.text.isEmpty?'Add Parts':'Edit Parts'),
              onPressed:()async{
                final v=await partsDialog(pa.text);
                if(v!=null){pa.text=v;setD((){});}
              }),
            if(pa.text.isNotEmpty)
              Align(alignment:Alignment.centerLeft,child:Text(
                pa.text.split('\n').map((x){
                  final z=x.split('|');
                  return z.length>=4?'${z[0]}  Qty:${z[1]}  Rate:${z[2]}  Total:${z[3]}':'$x';
                }).join('\n'))),
            const SizedBox(height:8),
            fld(r,'Remark / Extra Details'),
            DropdownButtonFormField<String>(
              value:status,
              decoration:const InputDecoration(labelText:'Call Status'),
              items:const[
                DropdownMenuItem(value:'Open',child:Text('Open')),
                DropdownMenuItem(value:'Pending',child:Text('Pending')),
                DropdownMenuItem(value:'Closed',child:Text('Closed'))],
              onChanged:(v)=>setD(()=>status=v??status))
          ])),
          actions:[
            TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Cancel')),
            FilledButton(onPressed:(){
              if(n.text.trim().isEmpty||m.text.trim().isEmpty)return;
              final now=DateTime.now();
              if(existing!=null){
                existing
                  ..jobNo=job.text.trim().isEmpty?_newJobNo():job.text.trim()
                  ..name=n.text.trim()..mobile=m.text.trim()..work=w.text.trim()
                  ..place=p.text.trim()..charges=ch.text.trim()..parts=pa.text.trim()
                  ..remark=r.text.trim()..status=status
                  ..closeDate=status=='Closed'?(existing.closeDate??now):null;
                Navigator.pop(c,existing);
              }else{
                Navigator.pop(c,Client(
                  jobNo:job.text.trim().isEmpty?_newJobNo():job.text.trim(),
                  name:n.text.trim(),mobile:m.text.trim(),work:w.text.trim(),
                  place:p.text.trim(),charges:ch.text.trim(),parts:pa.text.trim(),
                  remark:r.text.trim(),status:status,callDate:now,
                  closeDate:status=='Closed'?now:null));
              }
            },child:const Text('Save'))
          ])));
    for(final x in[job,n,m,w,p,ch,pa,r])x.dispose();
    return result;
  }

  Widget fld(TextEditingController c,String label,[TextInputType t=TextInputType.text])=>Padding(
    padding:const EdgeInsets.only(bottom:8),
    child:TextField(controller:c,keyboardType:t,
      decoration:InputDecoration(labelText:label,border:const OutlineInputBorder())));

  Widget watermark(){
    if(!watermarkEnabled)return const SizedBox.shrink();
    return Positioned(
      left:-23,
      top:MediaQuery.of(context).size.height*0.38,
      child:GestureDetector(
        onTap:watermarkControl,
        child:Transform.rotate(
          angle:-1.5708,
          child:Container(
            padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),
            decoration:BoxDecoration(
              color:Colors.black.withOpacity(.10),
              borderRadius:BorderRadius.circular(6)),
            child:Text('Saini Info Solutions',
              style:TextStyle(fontSize:11,fontWeight:FontWeight.bold,
                color:Colors.black.withOpacity(.38))),
          ))));
  }

  @override
  Widget build(BuildContext context){
    final list=clients.where((c)=>filter=='All'||c.status==filter).toList();
    return Scaffold(
      appBar:AppBar(
        title:Text(firmName),
        actions:[
          IconButton(tooltip:'Firm Settings',icon:const Icon(Icons.business),onPressed:firmSettings),
          PopupMenuButton<String>(
            onSelected:(v)=>setState(()=>filter=v),
            itemBuilder:(_)=>const[
              PopupMenuItem(value:'All',child:Text('All Calls')),
              PopupMenuItem(value:'Open',child:Text('Open')),
              PopupMenuItem(value:'Pending',child:Text('Pending')),
              PopupMenuItem(value:'Closed',child:Text('Closed'))])
        ]),
      body:Stack(children:[
        loading?const Center(child:CircularProgressIndicator()):
        list.isEmpty?const Center(child:Text('Abhi koi call nahi hai')):
        ListView.builder(
          padding:const EdgeInsets.all(10),
          itemCount:list.length,
          itemBuilder:(_,i){
            final c=list[i];
            return Card(child:ListTile(
              title:Text('${c.jobNo}  •  ${c.name}',style:const TextStyle(fontWeight:FontWeight.bold)),
              subtitle:Text('${c.mobile}\n${c.work}\n${c.place}\nStatus: ${c.status}',maxLines:4),
              isThreeLine:true,
              onTap:()=>edit(c),
              trailing:Wrap(children:[
                IconButton(tooltip:'WhatsApp',icon:const Icon(Icons.message,color:Colors.green),onPressed:()=>whatsapp(c)),
                PopupMenuButton<String>(
                  tooltip:'PDF Options',
                  icon:const Icon(Icons.picture_as_pdf,color:Colors.red),
                  onSelected:(v)=>v=='download'?downloadPdf(c):makePdf(c),
                  itemBuilder:(_)=>const[
                    PopupMenuItem(value:'download',child:ListTile(leading:Icon(Icons.download),title:Text('PDF Download'),contentPadding:EdgeInsets.zero)),
                    PopupMenuItem(value:'share',child:ListTile(leading:Icon(Icons.share),title:Text('PDF Share'),contentPadding:EdgeInsets.zero)),
                  ]),
                IconButton(tooltip:'Delete',icon:const Icon(Icons.delete_outline,color:Colors.red),onPressed:()=>deleteClient(c))
              ])));
          }),
        watermark()
      ]),
      floatingActionButton:FloatingActionButton.extended(
        onPressed:add,icon:const Icon(Icons.person_add),label:const Text('Client Add')));
  }
}
