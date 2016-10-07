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

extern int MaxTicketCount=2;
extern double Lots=0;
//extern double STPPer=0.07;

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
   double rsi0=getRSI(0,0);

   double bandsUp=getBands(MODE_UPPER,0,5);
   double bandLow=getBands(MODE_LOWER,0,5);
   double spread=MarketInfo(Symbol(),MODE_SPREAD)*Point*0.1;

   int sellscount=0;
   int buyscount=0;

//根据订单
   for(int pos=0;pos<OrdersTotal();pos++)
     {
      if(OrderSelect(pos,SELECT_BY_POS,MODE_TRADES)==false)
         continue;

      if(OrderSymbol()!=Symbol())
         continue;

      double profit=OrderProfit();//通过止损位止损
      if(profit<=0)
        {
         //判定风险并发出告警

         continue;
        }

      if(OrderComment()=="Bands" && OrderType()==OP_BUY && ((Bid-spread)>bandsUp) && IsTradeAllowed()==True)
        {
         //bool isMod=OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),newTakeProfit,0,OrangeRed);
         bool isMod=OrderClose(OrderTicket(),OrderLots(),Bid,3,OrangeRed);
         if(isMod==False)
           {SendNotification("BUY_OrderModify 失败 #"+ErrorDescription(GetLastError()));}
        }

      if(OrderComment()=="Bands" && OrderType()==OP_SELL && ((Ask+spread)<bandLow) && IsTradeAllowed()==True)
        {
         //bool isMod=OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),newTakeProfit,0,LawnGreen);
         bool isMod=OrderClose(OrderTicket(),OrderLots(),Ask,3,LawnGreen);
         if(isMod==False)
           {SendNotification("SELL_OrderModify 失败 #"+ErrorDescription(GetLastError()));}
        }

      if(OrderComment()=="RSI")//通过RSI止盈
        {
         //先将上面策略回测
        }
     }

   if(barCount==Bars){return;}//订单已下

   if(buyscount<MaxTicketCount)
     {
      if(
         (signalMacd1>mainMacd1 && signalMacd0<mainMacd0 && signalMacd0<0) && 
         (rsi0>75 || wr0>-15) && IsTradeAllowed()==True
         )
        {
         int ticket=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,Ask-STPPoint(),0,"Bands",2000,0,Red);
         if(ticket<0)
           {SendNotification("OP_BUY 失败错误 #"+ErrorDescription(GetLastError()));}
         else
           {barCount=Bars;}
        }
     }

   if(sellscount<MaxTicketCount)
     {
      if(
         (signalMacd1<mainMacd1 && signalMacd0>mainMacd0 && signalMacd0>0) && 
         (rsi0<25 || wr0<-85) && IsTradeAllowed()==True
         )
        {
         int ticket=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,Bid+STPPoint(),0,"Bands",1000,0,SeaGreen);
         if(ticket<0)
           {SendNotification("OP_SELL 失败错误 #"+ErrorDescription(GetLastError()));}
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
//+------------------------------------------------------------------+
//| 手数                                                                
//+------------------------------------------------------------------+
double LotsOptimized()
  {
   double lot=Lots;
   if(lot==0)
     {lot=MathFloor(AccountEquity()/100)/100.0;}

   if(lot>5){lot=5;}
   if(lot<0.01){lot=0.01;}

   return(lot);
  }
//+------------------------------------------------------------------+
//|止损                                                                  |
//+------------------------------------------------------------------+
double STPPoint()
  {
   return (AccountBalance()*STPPer/(LotsOptimized()*10))*Point*10;
  }
//+------------------------------------------------------------------+
//|已被ErrorDescription替代                                                             |
//+------------------------------------------------------------------+
string getErrorMsg(int errcode)
  {
   string errmsg="";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   switch(errcode)
     {
      case  0:
         errmsg="没有错误返回";
         break;
      case  1:
         errmsg="没有错误返回，但结果不明";
         break;
      case  2:
         errmsg="一般错误";
         break;
      case  3:
         errmsg="无效交易参数";
         break;
      case  4:
         errmsg="没交易服务器繁忙";
         break;
      case  5:
         errmsg="客户终端版本太旧";
         break;
      case  6:
         errmsg="没有连接服务器";
         break;
      case  7:
         errmsg="没有权限";
         break;
      case  8:
         errmsg="请求过于频繁";
         break;
      case  9:
         errmsg="无效交易";
         break;
      case  64:
         errmsg="账户禁用";
         break;
      case  65:
         errmsg="无效账户";
         break;
      case  128:
         errmsg="交易超时";
         break;
      case  129:
         errmsg="无效价格";
         break;
      case  130:
         errmsg="无效平仓";
         break;
      case  131:
         errmsg="无效交易量";
         break;
      case  132:
         errmsg="市场关闭";
         break;
      case  133:
         errmsg="交易被禁止";
         break;
      case  134:
         errmsg="资金不足";
         break;
      case  135:
         errmsg="价格已变动";
         break;
      case  136:
         errmsg="无报价";
         break;
      case  137:
         errmsg="经纪繁忙";
         break;
      case  138:
         errmsg="重新报价";
         break;
      case  139:
         errmsg="定单被锁定";
         break;
      case  140:
         errmsg="只允许多头头寸";
         break;
      case  141:
         errmsg="请求过多";
         break;
      case  145:
         errmsg="因为订单过于接近市价，修改被拒绝";
         break;
      case  146:
         errmsg="交易系统忙";
         break;
      case  147:
         errmsg="交易过期，被经纪商拒绝";
         break;
      case  148:
         errmsg="开仓和挂单总数已经达到经纪商的限定";
         break;
      case  149:
         errmsg="当对冲功能被关闭时，尝试开仓一个和现有仓位相反的订单";
         break;
      case  150:
         errmsg="尝试关闭一个违反FIFO规则的订单";
         break;
      default:
         errmsg="未知错误";
         break;
     }
   return errmsg;
  }
//+------------------------------------------------------------------+
