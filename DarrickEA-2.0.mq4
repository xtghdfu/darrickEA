//+------------------------------------------------------------------+
//|                                                DarrickEA-2.0.mq4 |
//|                2016-2016, Darrick Software Corp by 几何网创始人. |
//|                                          https://www.darrick.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016,Darrick Software Corp."
#property link      "Darrick-2.0 at 2016-10-21"
#property version   "16.10"
#property strict

#include <stderror.mqh>
#include <stdlib.mqh>

//是否允许下单
extern bool AllowSendOrder=True;
//账户交易金额百分比
extern double MaxTradeMoneyPec=0.4;

extern bool AllowBands=True;
extern bool AllowRSI=True;

int barCount;
int calBarCount;
int TicketDirect=0;//0为任意，1为多，-1为空，人工判定
double buybanditv;
double sellbanditv;
double HighValueOf;
double LowValueOf;

bool buyOpen=True;
bool sellOpen=True;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   barCount=Bars;
   calBarCount=Bars;
   CacleMaxVal();
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   double signalMacd0=getMACD(MODE_SIGNAL,0,6)/Point;
   double signalMacd1=getMACD(MODE_SIGNAL,1,6)/Point;
   double signalMacd2=getMACD(MODE_SIGNAL,2,6)/Point;
   double mainMacd0=getMACD(MODE_MAIN,0,6)/Point;
   double mainMacd1=getMACD(MODE_MAIN,1,6)/Point;
   double mainMacd2=getMACD(MODE_MAIN,2,6)/Point;

   double wr0=getWPR(0,0);
   double wr1=getWPR(1,0);
   double rsi0=getRSI(0,0);
   double rsi1=getRSI(1,0);

   double bandsUp=getBands(MODE_UPPER,0,5);
   double bandsLow=getBands(MODE_LOWER,0,5);

   bool bandssellcount=False;
   bool bandsbuycount=False;

   if(calBarCount!=Bars)
     {CacleMaxVal();calBarCount=Bars;}

   for(int pos=0;pos<OrdersTotal();pos++)
     {
      if(OrderSelect(pos,SELECT_BY_POS,MODE_TRADES)==false)
         continue;

      if(OrderSymbol()!=Symbol())
         continue;

      double profit=OrderProfit();

      if(OrderComment()=="Bands" && OrderType()==OP_BUY && IsTradeAllowed()==True)
        {
         bandsbuycount=True;

         if(profit>0)
           {
            if(Bid>=bandsUp)
              {
               bool isMod=OrderClose(OrderTicket(),OrderLots(),Bid,3,OrangeRed);
               if(isMod==False)
                 {SendNotification("BUY_OrderClose Bands Stragety Failed # "+ErrorDescription(GetLastError()));}
               else
                 {
                  bandsbuycount=False;
                  barCount=Bars;
                 }
              }
            else
              {
               double sl=0;

               double oop=OrderOpenPrice();
               double osl=OrderStopLoss();
               double cls=Bid;
               if(oop-osl>0)
                 {
                  if(cls-osl>30*Point+buybanditv)
                    {
                     sl=osl+Point*(oop-osl)/2;
                    }
                 }
               else
                 {
                  if(osl-oop>25*Point+buybanditv)
                    {
                     sl=osl+Point*(oop-osl)/2;
                    }
                 }

               if(sl!=0)
                 {
                  bool isMod=OrderModify(OrderTicket(),oop,sl,0,0,OrangeRed);
                  if(isMod==False)
                    {SendNotification("BUY_Modify StopLoss Failed # "+ErrorDescription(GetLastError()));}
                 }
              }
           }
        }

      if(OrderComment()=="Bands" && OrderType()==OP_SELL && IsTradeAllowed()==True)
        {
         bandssellcount=True;

         if(profit>0)
           {
            if(Ask<=bandsLow)
              {
               bool isMod=OrderClose(OrderTicket(),OrderLots(),Ask,3,LawnGreen);
               if(isMod==False)
                 {SendNotification("SELL_OrderClose Bands Stragety Failed # "+ErrorDescription(GetLastError()));}
               else
                 {
                  bandssellcount=False;
                  barCount=Bars;
                 }
              }
            else
              {
               double sl=0;
               double oop=OrderOpenPrice();
               double osl=OrderStopLoss();
               double cls=Ask;

               if(oop-osl<0)
                 {
                  if(osl-cls>30*Point+buybanditv)
                    {
                     sl=osl-Point*(oop-osl)/2;
                    }
                 }
               else
                 {
                  if(oop-osl>25*Point+buybanditv)
                    {
                     sl=osl-Point*(oop-osl)/2;
                    }
                 }

               if(sl!=0)
                 {
                  bool isMod=OrderModify(OrderTicket(),oop,sl,0,0,LawnGreen);
                  if(isMod==False)
                    {SendNotification("SELL_Modify StopLoss  Failed # "+ErrorDescription(GetLastError()));}
                 }
              }
           }
        }

      if(OrderComment()=="RSI" && OrderType()==OP_BUY && IsTradeAllowed()==True)
        {
         if(profit>0 && wr0<=-30 && rsi0<=60)//Bid>bandsUp
           {

            bool isMod=OrderClose(OrderTicket(),OrderLots(),Bid,3,OrangeRed);
            if(isMod==False)
              {SendNotification("BUY_OrderClose Bands Stragety Failed # "+ErrorDescription(GetLastError()));}
            else
              {
               buyOpen=True;
               barCount=Bars;
              }
           }
        }

      if(OrderComment()=="RSI" && OrderType()==OP_SELL && IsTradeAllowed()==True)
        {
         if(profit>0 && wr0>=-70 && rsi0>=40)//Ask<bandsLow
           {
            bool isMod=OrderClose(OrderTicket(),OrderLots(),Ask,3,GreenYellow);
            if(isMod==False)
              {SendNotification("BUY_OrderClose Bands Stragety Failed # "+ErrorDescription(GetLastError()));}
            else
              {
               sellOpen=True;
               barCount=Bars;
              }
           }
        }
     }

   if(!checkOpen()){return;}

//use in usdjpy
//int defaultDirect=TicketDirect;
//if(HighValueOf>=Ask+300*Point || HighValueOf<=Ask){TicketDirect=-1;}
//else if(LowValueOf>=Bid || Bid-300*Point>=LowValueOf){TicketDirect=1;}
//else{TicketDirect=defaultDirect;}

//use in eurusd
   if(HighValueOf<=Ask+300*Point){TicketDirect=-1;}
   else if(Bid-300*Point<=LowValueOf){TicketDirect=1;}
   else{TicketDirect=0;}
   Print("HighValueOf<=Ask+300*Point  :",HighValueOf<=Ask+300*Point,"  Bid-300*Point<=LowValueOf",Bid-300*Point<=LowValueOf,"   TicketDirect:",TicketDirect);

   if(!bandsbuycount)
     {
      if(AllowBands==True && (signalMacd1>mainMacd1 && signalMacd0<mainMacd0 && signalMacd0<0) && 
         wr0>=-15 && IsTradeAllowed()==True && TicketDirect!=-1 && AllowSendOrder==True
         )
        {
         int ticket=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,0,Ask+((bandsUp-bandsLow)/2),"Bands",1000,0,Red);

         if(ticket<0)
           {SendNotification("Bands Buy Order Failed # "+ErrorDescription(GetLastError()));}
         else
           {
            barCount=Bars;
            buybanditv=bandsUp-bandsLow;
           }
        }
     }

   if(!bandssellcount)
     {
      if(AllowBands==True && (signalMacd1<mainMacd1 && signalMacd0>mainMacd0 && signalMacd0>0) && 
         wr0<=-85 && IsTradeAllowed()==True && TicketDirect!=1 && AllowSendOrder==True
         )
        {
         int ticket=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,0,Bid-((bandsUp-bandsLow)/2),"Bands",1001,0,SeaGreen);
         if(ticket<0)
           {SendNotification("Bands Sell Order Failed # "+ErrorDescription(GetLastError()));}
         else
           {
            barCount=Bars;
            sellbanditv=bandsUp-bandsLow;
           }
        }
     }

   if(AllowRSI==True && wr0>=-20 && rsi0>=70 && buyOpen==True && TicketDirect!=-1 && AllowSendOrder==True)
     {
      int ticket=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,0,0,"RSI",2000,0,Tan);

      if(ticket<0)
        {SendNotification("RIS Buy Order Failed # "+ErrorDescription(GetLastError()));}
      else
        {
         barCount=Bars;
         buyOpen=False;
         sellOpen=True;
        }
     }

   if(AllowRSI==True && wr0<=-80 && rsi0<=30 && sellOpen==True && TicketDirect!=1 && AllowSendOrder==True)
     {
      int ticket=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,0,0,"RSI",2001,0,SkyBlue);

      if(ticket<0)
        {SendNotification("RIS Sell Order Failed # "+ErrorDescription(GetLastError()));}
      else
        {
         barCount=Bars;
         sellOpen=False;
         buyOpen=True;
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool checkOpen()
  {
   bool result=False;

   if(barCount==Bars){return result;}

   double canUseMoney=AccountEquity()-AccountMargin();
   if(canUseMoney<=AccountBalance()/2)
     {
      Print("Money is not enough ! # ",canUseMoney);
      return result;
     }

   return True;
  }
//+------------------------------------------------------------------+
//| MACD指标                                                            
//+------------------------------------------------------------------+
double getMACD(int mode,int shift,int digit)
  {
   return NormalizeDouble(iMACD(Symbol(),0,12,26,9,PRICE_CLOSE,mode,shift),digit);
  }
//+------------------------------------------------------------------+
//| Bands指标                                                              
//+------------------------------------------------------------------+
double getBands(int mode,int shift,int digit)
  {
   return NormalizeDouble(iBands(Symbol(),0,20,2,0,PRICE_CLOSE,mode,shift),digit);
  }
//+------------------------------------------------------------------+ 
//| RSI指标                 、
//+------------------------------------------------------------------+
double getRSI(int shift,int digit)
  {
   return NormalizeDouble(iRSI(Symbol(),0,5,PRICE_CLOSE,shift),digit);
  }
//+------------------------------------------------------------------+
//| WR指标                                                              
//+------------------------------------------------------------------+
double getWPR(int shift,int digit)
  {
   return NormalizeDouble(iWPR(Symbol(),0,6,shift),digit);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CacleMaxVal()
  {
   if(calBarCount>0)
     {
      HighValueOf=High[iHighest(NULL,0,MODE_HIGH,144,0)];
      LowValueOf=Low[iLowest(NULL,0,MODE_LOW,144,0)];
      //Print("HighValueOf:",HighValueOf,"   LowValueOf:",LowValueOf);
     }
  }
//-----------------------------------------------------------------+
//| 手数                                                                
//+------------------------------------------------------------------+
double LotsOptimized()
  {
//最多可损失的点数为4000 
   int maxPoint=4000;
   double returnLot=0.01;

   if(OrdersTotal()>15)
     {return returnLot;}
 
   if(lostProfit<=-acctMoney/2)
     {return returnLot; }//负订单不多于5个

   double acctMoney=AccountBalance();
   double haveMoney=AccountEquity()-AccountMargin();

   double useMoney=haveMoney-acctMoney*(1-MaxTradeMoneyPec);

   if(useMoney>0)
     {
      returnLot=useMoney/maxPoint;

      if(returnLot<0.01)
        {
         returnLot=0.01;
        }

      if(haveMoney<=1000 && returnLot>0.1)
        {
         returnLot=0.1;
        }

      if(haveMoney>1000 && haveMoney<=10000 && returnLot>0.5)
        {
         returnLot=0.5;
        }

      if(haveMoney>10000 && haveMoney<=50000 && returnLot>1)
        {
         returnLot=1;
        }
     }

//Print("returnLot:",returnLot,"  useMoney:",useMoney,"   haveMoney:",haveMoney,"  acctMoney:",acctMoney);
   return returnLot;
  }
//+------------------------------------------------------------------+
