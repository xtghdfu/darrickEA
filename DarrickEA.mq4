//+------------------------------------------------------------------+
//|                                                    DarrickEA.mq4 |
//|                           Copyright 2016, Darrick Software Corp. |
//|                                          https://www.darrick.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016,Darrick Software Corp."
#property link      "Darrick at 2016-9-21"
#property version   "16.10"
#property strict

#include <stderror.mqh>
#include <stdlib.mqh>


int barCount;

double buybanditv;
double sellbanditv;
double buyrsiitv;
double sellrsiitv;
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
//double spread=MarketInfo(Symbol(),MODE_SPREAD)*Point;

   bool bandssellcount=False;
   bool bandsbuycount=False;

   bool rsisellcount=False;
   bool rsibuycount=False;

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
         rsibuycount=True;

         double sl=0;
         double oop=OrderOpenPrice();
         double osl=OrderStopLoss();
         double cls=Bid;

         if(profit>0)
           {

           }
        }

      if(OrderComment()=="RSI" && OrderType()==OP_SELL && IsTradeAllowed()==True)
        {
         rsisellcount=True;

         if(profit)
           {
            Print("进来了");
            if((Ask-OrderOpenPrice())>(OrderStopLoss()-OrderOpenPrice()/2))
              {
               bool isMod=OrderClose(OrderTicket(),OrderLots(),Ask,3,OrangeRed);
               if(isMod==False)
                 {SendNotification("BUY_OrderClose Bands策略 失败 #"+ErrorDescription(GetLastError()));}
               else
                 {
                  bandsbuycount=False;
                  barCount=Bars;
                 }
              }
           }
        }
     }

   if(barCount==Bars){return;}

   if(!bandsbuycount)
     {
      if(1==0 && //---------要处理
         (signalMacd1>mainMacd1 && signalMacd0<mainMacd0 && signalMacd0<0) && 
         wr0>=-15 && IsTradeAllowed()==True
         )
        {
         int ticket=OrderSend(Symbol(),OP_BUY,LotsOptimized(OP_BUY),Ask,3,Ask-bandsUp+bandsLow,Ask+((bandsUp-bandsLow)/2),"Bands",1000,0,Red);
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
         wr0<=-85 && IsTradeAllowed()==True
         )
        {
         int ticket=OrderSend(Symbol(),OP_SELL,LotsOptimized(OP_SELL),Bid,3,Bid+bandsUp-bandsLow,Bid-((bandsUp-bandsLow)/2),"Bands",1001,0,SeaGreen);
         if(ticket<0)
           {SendNotification("SELL Bands策略开单 失败错误 #"+ErrorDescription(GetLastError()));}
         else
           {
            barCount=Bars;
            sellbanditv=bandsUp-bandsLow;
           }
        }
     }

   if(!rsibuycount)
     {
      Print("rsibuy");
      if(wr0>=-15 && rsi0>75)
        {
         int ticket=OrderSend(Symbol(),OP_BUY,LotsOptimized(OP_BUY),Ask,3,Ask-bandsUp+bandsLow,0,"RSI",2000,0,Tan);
         if(ticket<0)
           {SendNotification("SELL RIS策略开单 失败错误 #"+ErrorDescription(GetLastError()));}
         else
           {barCount=Bars;}
        }
     }

   if(!rsisellcount)
     {
      Print("rsisell");
      if(wr0<-85 && rsi0<35)
        {
         int ticket=OrderSend(Symbol(),OP_SELL,LotsOptimized(OP_SELL),Bid,3,Bid+bandsUp-bandsLow,0,"RSI",2001,0,SkyBlue);
         if(ticket<0)
           {SendNotification("SELL RIS策略开单 失败错误 #"+ErrorDescription(GetLastError()));}
         else
           {barCount=Bars;}
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
double LotsOptimized(int op)
  {
   double resultVal=0.01;
   double buyLot=0.01;
   double sellLot=0.01;

   int iCount=0;

   return resultVal;

   for(int pos=0;pos<OrdersHistoryTotal();pos++)
     {
      if(iCount>5)
        {break;}

      if(OrderSelect(pos,SELECT_BY_POS,MODE_HISTORY)==false)
        {
         SendNotification("访问历史订单失败 错误信息 #"+ErrorDescription(GetLastError()));
         continue;
        }

      if(OrderComment()!="RSI" || OrderSymbol()!=Symbol())
        {continue;}

      double profit=OrderProfit();
      if(OrderType()==OP_BUY)
        {
         buyLot+=0.01;
         sellLot-=0.01/2;
        }

      if(OrderType()==OP_SELL)
        {
         sellLot+=0.01;
         buyLot-=0.01/2;
        }

      iCount++;
     }
   Print("sellLot:",sellLot,"  buyLot:",buyLot);

   buyLot=NormalizeDouble(buyLot,2);
   sellLot=NormalizeDouble(sellLot,2);

   if(sellLot<0.01)
     {sellLot=0.01;}

   if(buyLot<0.01)
     {buyLot=0.01;}

   if(op==OP_BUY)
      resultVal=buyLot;

   if(op==OP_SELL)
      resultVal=sellLot;

   return resultVal;
  }

//+------------------------------------------------------------------+
