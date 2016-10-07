//+------------------------------------------------------------------+
//|                                                    DarrickEA.mq4 |
//|                           Copyright 2016, Darrick Software Corp. |
//|                                          https://www.darrick.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016,Darrick Software Corp."
#property link      "Darrick at 2016-9-21"
#property version   "16.10"
#property strict


//RSI周期设定为11
extern int MaxTicketCount=3;
extern double Lots=0;
extern double STPPer=0.07;

int barCount;
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
   if(          IsTradeAllowed()==False)
      return;

   DoWork();
  }
//+------------------------------------------------------------------+
//|                                                                  
//+------------------------------------------------------------------+
void DoWork()
  {
   double signalMacd0=getMACD(MODE_SIGNAL,0,6)/Point;
   double signalMacd1=getMACD(MODE_SIGNAL,1,6)/Point;
   double mainMacd0=getMACD(MODE_MAIN,0,6)/Point;
   double mainMacd1=getMACD(MODE_MAIN,1,6)/Point;

   double bandsUp=getBands(MODE_UPPER,0,5);
   double bandLow=getBands(MODE_LOWER,0,5);
   double spread=MarketInfo(Symbol(),MODE_SPREAD)*Point*0.1;

   if((Ask+spread)<bandLow)
     {
      for(int pos=0;pos<OrdersTotal();pos++)
        {
         if(OrderSelect(pos,SELECT_BY_POS,MODE_TRADES)==false)
            continue;

         if(OrderType()==OP_SELL && OrderSymbol()==Symbol())
           {
            //若盈利大于0则止盈线，当前的止盈线不得小于之前订单止盈线
            double profit=OrderProfit();

            if(profit<=0){continue;}

            double takeprofit=OrderTakeProfit();
            double newTakeProfit=NormalizeDouble(Ask,Digits);

            if(newTakeProfit==takeprofit)
               continue;

            if((newTakeProfit<takeprofit || takeprofit==0) && OrderComment()=="Robot")
              {
               //Print("做空    定单盈利",profit,"   旧止盈值:",takeprofit,"   新止盈值：",newTakeProfit,"  ASK:",Ask,"  Bid:",Bid,"  中间价：",(Ask+Bid)/2);
               bool isMod=OrderModify(OrderTicket(),OrderOpenPrice(),0,newTakeProfit,0,Blue);
               if(isMod==False)
                 {
                  SendNotification("OrderModify 失败错误 #"+GetLastError());
                 }
              }
           }
        }
     }

   if((Bid-spread)>bandsUp)
     {
      for(int pos=0;pos<OrdersTotal();pos++)
        {
         if(OrderSelect(pos,SELECT_BY_POS,MODE_TRADES)==false)
            continue;

         if(OrderType()==OP_BUY && OrderSymbol()==Symbol())
           {
            double profit=OrderProfit();

            if(profit<=0){continue;}

            double takeprofit=OrderTakeProfit();
            double newTakeProfit=NormalizeDouble(Bid,Digits);

            if(newTakeProfit==takeprofit)
               continue;

            if((newTakeProfit>takeprofit || takeprofit==0) && OrderComment()=="Robot")
              {
               //Print("做多    定单盈利",profit,"   旧止盈值:",takeprofit,"   
               //新止盈值：",newTakeProfit,"  ASK:",Ask,"  Bid:",Bid,"  中间价：",(Ask+Bid)/2);
               bool isMod=OrderModify(OrderTicket(),OrderOpenPrice(),0,newTakeProfit,0,Blue);
               if(isMod==False)
                 {
                  SendNotification("OrderModify 失败错误 #"+GetLastError());
                 }
              }
           }
        }
     }

   if(barCount==Bars){return;}

   if(signalMacd1<mainMacd1 && 
      signalMacd0>mainMacd0 && 
      signalMacd0>0)
     {
      int iflag=0;
      int maxcount=0;
      for(int pos=0;pos<OrdersTotal();pos++)
        {
         if(OrderSelect(pos,SELECT_BY_POS,MODE_TRADES)==false)
            continue;

         if(OrderType()==OP_SELL)
           {
            maxcount++;
           }
        }

      if(maxcount<MaxTicketCount)
        {
         int ticket=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,0,0,"Robot",1000,0,Yellow);
         if(ticket<0)
           {
            SendNotification("OP_SELL 失败错误 #"+GetLastError());
           }
         else
           {
            barCount=Bars;
           }
        }
     }

   if(signalMacd1>mainMacd1 && 
      signalMacd0<mainMacd0 && 
      signalMacd0<0)
     {
      int iflag=0;
      int maxcount=0;
      for(int pos=0;pos<OrdersTotal();pos++)
        {
         if(OrderSelect(pos,SELECT_BY_POS,MODE_TRADES)==false)
            continue;

         if(OrderType()==OP_BUY)
           {
            maxcount++;
           }
        }

      if(maxcount<MaxTicketCount)
        {
         int ticket=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,0,0,"Robot",2000,0,Red);
         if(ticket<0)
           {
            SendNotification("OP_BUY 失败错误 #"+GetLastError());
           }
         else
           {
            barCount=Bars;
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| MACD指标                                                            
//+------------------------------------------------------------------+
double getMACD(int mode,int shift,int digit)
  {
   return NormalizeDouble(iMACD(Symbol(),0,8,13,9,PRICE_CLOSE,mode,shift),digit);
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
double getRSI(int peroid,int shift,int digit)
  {
   return NormalizeDouble(iRSI(Symbol(),0,peroid,PRICE_CLOSE,shift),digit);
  }
//+------------------------------------------------------------------+
//| WR指标                                                              
//+------------------------------------------------------------------+
double getWPR(int peroid,int shift,int digit)
  {
   return NormalizeDouble(iWPR(Symbol(),0,peroid,shift),digit);
  }
//+------------------------------------------------------------------+
//| 手数                                                                
//+------------------------------------------------------------------+
double LotsOptimized()
  {
   double lot=Lots;
   if(lot==0)
     {lot=MathFloor(AccountBalance()/100)/100.0;}

   if(lot>5){lot=5;}

   return(lot);
  }
//+------------------------------------------------------------------+
//|止损                                                                  |
//+------------------------------------------------------------------+
double STPLevel()
  {
   return 0;

  }
//+------------------------------------------------------------------+
