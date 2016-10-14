//+------------------------------------------------------------------+
//|                                                    DarrickEA.mq4 |
//|                2016-2016, Darrick Software Corp by 几何网创始人. |
//|                                          https://www.darrick.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016,Darrick Software Corp."
#property link      "Darrick at 2016-9-21"
#property version   "16.10"
#property strict

#include <stderror.mqh>
#include <stdlib.mqh>

extern int TicketDirect=0;//0为任意，1为多，-1为空，人工判定

int barCount;

double buybanditv;
double sellbanditv;

bool buyOpen=True;//for rsi
bool sellOpen=True;
//+------------------------------------------------------------------+
//Tip:
//symbol        - 要计算指标数据的货币对名称。 NULL表示当前货币对。
//timeframe     - 时间周期。 可以 时间周期列举 任意值。 0表示当前图表的时间周期。 
//+------------------------------------------------------------------+
int OnInit()
  {
   barCount=Bars;
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                   
//+------------------------------------------------------------------+
void OnTick()
  {
   DoWork();
  }
//+------------------------------------------------------------------+
//|                                                                  
//+------------------------------------------------------------------+
void DoWork()
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
                 {SendNotification("BUY_OrderClose Bands策略 失败 #"+ErrorDescription(GetLastError()));}
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
                    {SendNotification("BUY_Modify StopLoss  失败 #"+ErrorDescription(GetLastError()));}
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
                 {SendNotification("SELL_OrderClose Bands策略 失败 #"+ErrorDescription(GetLastError()));}
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
                    {SendNotification("SELL_Modify StopLoss 失败 #"+ErrorDescription(GetLastError()));}
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
              {SendNotification("BUY_OrderClose Bands策略 失败 #"+ErrorDescription(GetLastError()));}
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
              {SendNotification("BUY_OrderClose Bands策略 失败 #"+ErrorDescription(GetLastError()));}
            else
              {
               sellOpen=True;
               barCount=Bars;
              }
           }
        }
     }

   if(barCount==Bars){return;}

   double lotsO=LotsOptimized();

   if(lotsO==0)
     {
      Alert("Money is not enough，不满足开单要求");
      return;
     }

   if(!bandsbuycount)
     {
      if(1==0 && //---------要处理
         (signalMacd1>mainMacd1 && signalMacd0<mainMacd0 && signalMacd0<0) && 
         wr0>=-15 && IsTradeAllowed()==True && TicketDirect !=-1
         )
        {
         int ticket=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,Ask-bandsUp+bandsLow,Ask+((bandsUp-bandsLow)/2),"Bands",1000,0,Red);
         
         if(ticket<0)
           {SendNotification("BUY Bands策略开单 失败错误 #"+ErrorDescription(GetLastError()));}
         else
           {
            barCount=Bars;
            buybanditv=bandsUp-bandsLow;
           }
        }
     }

   if(!bandssellcount)
     {
      if(1==0 && //---------要处理
         (signalMacd1<mainMacd1 && signalMacd0>mainMacd0 && signalMacd0>0) && 
         wr0<=-85 && IsTradeAllowed()==True && TicketDirect !=1
         )
        {
         int ticket=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,Bid+bandsUp-bandsLow,Bid-((bandsUp-bandsLow)/2),"Bands",1001,0,SeaGreen);
         if(ticket<0)
           {SendNotification("SELL Bands策略开单 失败错误 #"+ErrorDescription(GetLastError()));}
         else
           {
            barCount=Bars;
            sellbanditv=bandsUp-bandsLow;
           }
        }
     }

   if(wr0>=-20 && rsi0>=70 && buyOpen==True && TicketDirect !=-1)
     {
      int ticket=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,0,0,"RSI",2000,0,Tan);

      if(ticket<0)
        {SendNotification("Buy RIS策略开单 失败错误 #"+ErrorDescription(GetLastError()));}
      else
        {
        	barCount=Bars;
        	buyOpen=False;
        	sellOpen=True;
        }
     }

   if(wr0<=-80 && rsi0<=30 && sellOpen==True && TicketDirect !=1)
     {
      int ticket=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,0,0,"RSI",2001,0,SkyBlue);

      if(ticket<0)
        {SendNotification("Sell RIS策略开单 失败错误 #"+ErrorDescription(GetLastError()));}
      else
        {
        	barCount=Bars;
        	sellOpen=False;
        	buyOpen=True;
        }
     }
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
//-----------------------------------------------------------------+
//| 手数                                                                
//+------------------------------------------------------------------+
double LotsOptimized()
  {
   int maxPoint=4000;
   double returnLot=0;

   if(OrdersTotal()>10)
     {return returnLot;}

   int k=0;
   double lostProfit=0;
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false)
         continue;
      double profit=OrderProfit();
      if(profit<0)
        {
         lostProfit=lostProfit+profit;
        }
     }

   double acctMoney=AccountBalance();

   if(lostProfit<=-acctMoney/2)
     {return returnLot; }//负订单不少于5个

   double haveMoney=AccountEquity()-AccountMargin();

   double useMoney=haveMoney-acctMoney*0.6;

   if(useMoney>0)
     {
      returnLot=useMoney/maxPoint;
      if(returnLot<0.01)
        {returnLot=0.01;}
     }

   Print("returnLot:",returnLot,"  useMoney:",useMoney,"   haveMoney:",haveMoney,"  acctMoney:",acctMoney);

   return returnLot;
  }
//+------------------------------------------------------------------+
