//+------------------------------------------------------------------+
//|                                                    DarrickEA.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016,Darrick Software Corp."
#property link      "DZ at 2016-6-30"
#property version   "1.01"
#property strict

#define MAGICMA_MA_BUY 11
#define MAGICMA_MA_SELL 12
#define MAGICMA_BOLL_BUY 21
#define MAGICMA_BOLL_SELL 22
#define MAGICMA_Alligator_BUY 31
#define MAGICMA_Alligator_SELL 32
#define MAGICMA_RSI_BUY 41
#define MAGICMA_RSI_SELL 42

#define MAGICMA_Strategy_One 101 //策略1

extern int barCount;
extern int interval1=70;

extern bool MA_ACTIVE=false;
extern bool BOLL_ACTIVE=false;
extern bool RSI_ACTIVE=true;
extern bool AllIGATOR_ACTIVE=false;

extern double vMa01;
extern double vMa02;
extern double vMa03;
extern double vMa11;
extern double vMa12;
extern double vMa13;
extern double vMa21;
extern double vMa22;
extern double vMa23;
extern double vMa31;
extern double vMa32;
extern double vMa33;

extern double bandsUp0;
extern double bandsLow0;
extern double bandsUp1;
extern double bandsLow1;
extern double bandsUp2;
extern double bandsLow2;
extern double bandsMa0;
extern double bandsMa1;
extern double bandsMa2;
extern double rsi0;
extern double rsi1;

extern double alligatorTop0;
extern double alligatorCenter0;
extern double alligatorBottom0;
extern double alligatorTop1;
extern double alligatorCenter1;
extern double alligatorBottom1;
extern double alligatorTop2;
extern double alligatorCenter2;
extern double alligatorBottom2;

extern double atrPips;


#import "DarrickEADLL.dll"
int Test(int a,int b);
#import
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   barCount=Bars;
   return(INIT_SUCCEEDED);
   int result=Test(1,2);
  }
//建仓
void OpenOrder(string op,int magicma)
  {
   int res;

   if(op=="buy")
     {
      res=OrderSend(Symbol(),OP_BUY,0.01,Ask,3,0,0,"",magicma,0,Green);
      Print("买单建仓成功！ result",Ask," magicma :",magicma);
     }

   if(op=="sell")
     {
      res=OrderSend(Symbol(),OP_SELL,0.01,Bid,3,0,0,"",magicma,0,Yellow);
      Print("卖单建仓成功！ at ",Bid," magicma :",magicma);
     }
  }
//平仓
void CloseOrder(int magicma)
  {
   int orderTotal=OrdersTotal();

   for(int pos=0;pos<orderTotal;pos++)
     {
      if(OrderSelect(pos,SELECT_BY_POS,MODE_TRADES)==false)
         continue;

      if(OrderMagicNumber()!=magicma || OrderSymbol()!=Symbol())
         continue;

      if(OrderType()==OP_BUY)
        {
         bool res=OrderClose(OrderTicket(),OrderLots(),Bid,3,White);
         if(!res)
            Print("买单平仓异常:",GetLastError());
         else
            Print("买单平仓成功！ magicma :",magicma);
        }

      if(OrderType()==OP_SELL)
        {
         bool res=OrderClose(OrderTicket(),OrderLots(),Ask,3,White);

         if(!res)
            Print("卖单平仓异常:",GetLastError());
         else
            Print("卖单平仓成功！ magicma :",magicma);
        }
     }
  }
//检测开仓
void CheckForOpen()
  {
   int orderTotal=OrdersTotal();

   int ma_buy=0;
   int ma_sell=0;
   int boll_buy=0;
   int boll_sell=0;
   int alligator_buy=0;
   int alligator_sell=0;
   int rsi_buy=0;
   int rsi_sell=0;

   string op;

   for(int pos=0;pos<orderTotal;pos++)
     {
      if(OrderSelect(pos,SELECT_BY_POS,MODE_TRADES)==false)
         continue;

      if

      if(ma_buy==0 && OrderMagicNumber()==MAGICMA_MA_BUY && OrderSymbol()==Symbol())
         ma_buy=MAGICMA_MA_BUY;

      if(ma_sell==0 && OrderMagicNumber()==MAGICMA_MA_SELL && OrderSymbol()==Symbol())
         ma_sell=MAGICMA_MA_SELL;

      if(boll_buy==0 && OrderMagicNumber()==MAGICMA_BOLL_BUY && OrderSymbol()==Symbol())
         boll_buy=MAGICMA_BOLL_BUY;

      if(boll_sell==0 && OrderMagicNumber()==MAGICMA_BOLL_SELL && OrderSymbol()==Symbol())
         boll_sell=MAGICMA_BOLL_SELL;

      if(alligator_buy==0 && OrderMagicNumber()==MAGICMA_Alligator_BUY && OrderSymbol()==Symbol())
         alligator_buy=MAGICMA_Alligator_BUY;

      if(alligator_sell==0 && OrderMagicNumber()==MAGICMA_Alligator_SELL && OrderSymbol()==Symbol())
         alligator_sell=MAGICMA_Alligator_SELL;

      if(rsi_buy==0 && OrderMagicNumber()==MAGICMA_RSI_BUY && OrderSymbol()==Symbol())
         rsi_buy=MAGICMA_RSI_BUY;

      if(rsi_sell==0 && OrderMagicNumber()==MAGICMA_RSI_SELL && OrderSymbol()==Symbol())
         rsi_sell=MAGICMA_RSI_SELL;

     }

   if(ma_buy==0 && MA_ACTIVE)//MA买单
     {
      op="";
      int count=0;//仅有一条件有限效
      if(vMa01>vMa02)
        {
         if(Close[2]>=vMa22 && Open[1]>=vMa12 && Open[0]>vMa02)
           {
            op="buy";
            count+=1;
           }
        }

      if(count<=0 && vMa01>vMa02 && vMa02>vMa03)
        {
         if(Close[1]>=vMa12 && Close[2]>=vMa22 && Open[2]<=vMa22 && (MathAbs(vMa01-vMa02)/Point)>=interval1)//倒数2线open<=30,close>ma1,倒数1线close>ma1
           {
            op="buy";
           }
        }

      if(count<=0 && Close[2]>=vMa21 && Close[2]>=vMa22 && Close[2]>=vMa23 && Open[2]<=vMa22 && Open[2]<=vMa23 //&& Open[2]<=vMa21
         && Close[1]>=vMa11 && Close[1]>=vMa12 && Close[1]>=vMa13
         && Open[0]>=vMa01
         && vMa01>vMa03)
        {
         op="buy";
        }

      if(op!="")
         OpenOrder(op,MAGICMA_MA_BUY);
     }

   if(ma_sell==0 && MA_ACTIVE)//MA卖单
     {
      if(vMa01<vMa02 && vMa02<vMa03)
        {
         if(Close[1]<=vMa11 && Open[0]<=vMa01 && MathAbs((vMa01-vMa02)/Point)>interval1)
           {
            OpenOrder("sell",MAGICMA_MA_SELL);
           }
        }
     }

   if(boll_buy==0 && BOLL_ACTIVE)//BOLL买单
     {
      if(bandsUp0>=bandsUp1 && bandsUp1>=bandsUp2)
        {
         if(bandsLow0<=bandsLow1 && bandsLow1<=bandsLow2)
           {
            if(Open[0]>=Close[1] && Close[1]>=Close[2] && Low[2]<=bandsLow2)
               OpenOrder("buy",MAGICMA_BOLL_BUY);
           }
        }
     }

   if(boll_sell==0 && BOLL_ACTIVE)//BOLL卖单
     {
      if(bandsLow0<=bandsLow1 && bandsLow1<=bandsLow2)
        {
         if(Close[0]<=bandsUp0 && Close[1]<=bandsUp1 && Close[2]>bandsUp2 && Close[0]<Close[1])
            OpenOrder("sell",MAGICMA_BOLL_SELL);
        }
     }

   if(alligator_buy==0 && AllIGATOR_ACTIVE)//鳄鱼买单
     {

      //OpenOrder(op,MAGICMA_Alligator_BUY);
     }

   if(alligator_sell==0 && AllIGATOR_ACTIVE)//鳄鱼卖单
     {

      //OpenOrder(op,MAGICMA_Alligator_SELL);
     }

   if(rsi_buy==0 && RSI_ACTIVE)//RSI买单
     {
      //if(rsi0>=rsi1 && rsi1<=25)
      //   OpenOrder("buy",MAGICMA_RSI_BUY);
      //当alligatorTop >alligatorCenter>alligatorButtom
      Print("alligatorTop0蓝:",alligatorTop0," alligatorCenter0红:",alligatorCenter0,"  alligatorBottom0绿:",alligatorBottom0);
      Print("alligatorTop1蓝:",alligatorTop1," alligatorCenter1红:",alligatorCenter1,"  alligatorBottom1绿:",alligatorBottom1);
      Print("alligatorTop2蓝:",alligatorTop2," alligatorCenter12红:",alligatorCenter2,"  alligatorBottom2绿:",alligatorBottom2);
      if(alligatorTop0>alligatorCenter0 && alligatorCenter0>alligatorBottom0 && 
         !(alligatorTop1>alligatorCenter1 && alligatorCenter1>alligatorBottom1) && 
         !(alligatorTop2>alligatorCenter2 && alligatorCenter2>alligatorBottom2))
        {
         if(rsi0>=rsi1 && rsi1<=22)
           {
            OpenOrder("sell",MAGICMA_RSI_SELL);
            Alert("这时候符合开卖Sell单");
           }
         Print("能进卖");
        }



     }

   if(rsi_sell==0 && RSI_ACTIVE)//RSI卖单
     {
      if(alligatorTop0<alligatorCenter0 && alligatorCenter0<alligatorBottom0 && 
         !(alligatorTop1<alligatorCenter1 && alligatorCenter1<alligatorBottom1) && 
         !(alligatorTop2<alligatorCenter2 && alligatorCenter2<alligatorBottom2))
        {
         if(rsi0<rsi1 && rsi1>=74) //&& Close[1] >=bandsUp1 && Open[1]>Close[1])
           {
            OpenOrder("buy",MAGICMA_RSI_BUY);
            Alert("这时候符合开买Buy单");
           }
         Print("能进买");
        }
      Print("Close[1]:",Close[1],"  bandsUp1:",bandsUp1," Open[1]:",Open[1]);
     }

//Print("RSi0:",rsi0,"  RSi1:",rsi1," Open[1]:",Open[1]," bandsLow1:",bandsLow1);
  }
//检测平仓
void CheckForClose()
  {
   int orderTotal=OrdersTotal();

   int ma_buy=0;
   int ma_sell=0;
   int boll_buy=0;
   int boll_sell=0;
   int alligator_buy=0;
   int alligator_sell=0;
   int rsi_buy=0;
   int rsi_sell=0;

   for(int pos=0;pos<orderTotal;pos++)
     {
      if(OrderSelect(pos,SELECT_BY_POS,MODE_TRADES)==false)
         continue;

      if(ma_buy==0 && OrderMagicNumber()==MAGICMA_MA_BUY && OrderSymbol()==Symbol())
         ma_buy=MAGICMA_MA_BUY;

      if(ma_sell==0 && OrderMagicNumber()==MAGICMA_MA_SELL && OrderSymbol()==Symbol())
         ma_sell=MAGICMA_MA_SELL;

      if(boll_buy==0 && OrderMagicNumber()==MAGICMA_BOLL_BUY && OrderSymbol()==Symbol())
         boll_buy=MAGICMA_BOLL_BUY;

      if(boll_sell==0 && OrderMagicNumber()==MAGICMA_BOLL_SELL && OrderSymbol()==Symbol())
         boll_sell=MAGICMA_BOLL_SELL;

      if(alligator_buy==0 && OrderMagicNumber()==MAGICMA_Alligator_BUY && OrderSymbol()==Symbol())
         alligator_buy=MAGICMA_Alligator_BUY;

      if(alligator_sell==0 && OrderMagicNumber()==MAGICMA_Alligator_SELL && OrderSymbol()==Symbol())
         alligator_sell=MAGICMA_Alligator_SELL;

      if(rsi_buy==0 && OrderMagicNumber()==MAGICMA_RSI_BUY && OrderSymbol()==Symbol())
         rsi_buy=MAGICMA_RSI_BUY;

      if(rsi_sell==0 && OrderMagicNumber()==MAGICMA_RSI_SELL && OrderSymbol()==Symbol())
         rsi_sell=MAGICMA_RSI_SELL;
     }

   if(ma_buy>0 && MA_ACTIVE)
     {
      if(vMa01>vMa02 && vMa02>vMa03)
        {
         if((Close[2]<=vMa21 && Close[3]<=vMa31) || Close[1]<=vMa12)
           {
            CloseOrder(MAGICMA_MA_BUY);
           }
         else if(Close[1]<vMa11 && Close[2]>vMa21)
           {
            CloseOrder(MAGICMA_MA_BUY);
           }
        }
     }

   if(ma_sell>0 && MA_ACTIVE)
     {
      if(vMa01<vMa02 && vMa02<vMa03)
        {
         if(Close[1]>=vMa11 && Close[2]<=vMa21 && High[0]>=vMa02)//(Close[2]>=vMa21 && Close[3]>=vMa31) ||Close[1]>=vMa12)
           {
            CloseOrder(MAGICMA_MA_SELL);
           }
        }
     }

   if(boll_buy>0 && BOLL_ACTIVE)
     {
      if(Open[1]<bandsMa1 && Open[0]<bandsMa0 && Close[1]<bandsMa1)
        {
         CloseOrder(MAGICMA_BOLL_BUY);
        }
     }

   if(boll_sell>0 && BOLL_ACTIVE)
     {
      if(Open[2]>=bandsMa1 && Open[0]>=bandsMa0 && Close[1]>bandsMa1)
        {
         CloseOrder(MAGICMA_BOLL_SELL);
        }
     }

   if(alligator_buy>0 && AllIGATOR_ACTIVE)
     {

     }

   if(alligator_sell>0 && AllIGATOR_ACTIVE)
     {

     }

   if(rsi_buy>0 && RSI_ACTIVE)
     {
      if(rsi0>=72)
        {
         CloseOrder(MAGICMA_RSI_BUY);
        }
      else if(Open[2]>bandsMa2 && Close[2]>bandsMa2 && Open[1]>bandsMa1 && Close[1]>bandsMa1)
        {
         CloseOrder(MAGICMA_RSI_BUY);
        }

     }

   if(rsi_sell>0 && RSI_ACTIVE)
     {
      if(rsi0<=30)
        {
         CloseOrder(MAGICMA_RSI_SELL);
        }
      else if(rsi0>=70 && rsi1<70)
        {
         CloseOrder(MAGICMA_RSI_SELL);
        }
      else if((Open[1]<bandsLow1 && Close[1]<bandsLow1 && Close[2]<bandsLow2))
        {
         CloseOrder(MAGICMA_RSI_SELL);
        }
      else if(Open[1]<=bandsMa1 && Close[1]<bandsMa1 && Low[1]<bandsLow1)
        {
         CloseOrder(MAGICMA_RSI_SELL);
         Print("是这个关的");
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GetWork()
  {
   if(Bars<=barCount)
      return;
   else
      barCount=Bars;

   int ma1=5;
   int ma2=10;
   int ma3=20;

//均线参数初使化
   vMa01=iMA(Symbol(),0,ma1,0,MODE_EMA,PRICE_MEDIAN,0);
   vMa02=iMA(Symbol(),0,ma2,0,MODE_EMA,PRICE_MEDIAN,0);
   vMa03=iMA(Symbol(),0,ma3,0,MODE_EMA,PRICE_MEDIAN,0);
   vMa11=iMA(Symbol(),0,ma1,0,MODE_EMA,PRICE_MEDIAN,1);
   vMa12=iMA(Symbol(),0,ma2,0,MODE_EMA,PRICE_MEDIAN,1);
   vMa13=iMA(Symbol(),0,ma3,0,MODE_EMA,PRICE_MEDIAN,1);
   vMa21=iMA(Symbol(),0,ma1,0,MODE_EMA,PRICE_MEDIAN,2);
   vMa22=iMA(Symbol(),0,ma2,0,MODE_EMA,PRICE_MEDIAN,2);
   vMa23=iMA(Symbol(),0,ma3,0,MODE_EMA,PRICE_MEDIAN,2);
   vMa31=iMA(Symbol(),0,ma1,0,MODE_EMA,PRICE_MEDIAN,3);
   vMa32=iMA(Symbol(),0,ma2,0,MODE_EMA,PRICE_MEDIAN,3);
   vMa33=iMA(Symbol(),0,ma3,0,MODE_EMA,PRICE_MEDIAN,3);

   bandsUp0=StringToDouble(DoubleToStr(iBands(Symbol(),0,20,2,0,PRICE_CLOSE,MODE_UPPER,0),4));
   bandsLow0=StringToDouble(DoubleToStr(iBands(Symbol(),0,20,2,0,PRICE_CLOSE,MODE_LOWER,0),4));
   bandsUp1=StringToDouble(DoubleToStr(iBands(Symbol(),0,20,2,0,PRICE_CLOSE,MODE_UPPER,1),4));
   bandsLow1=StringToDouble(DoubleToStr(iBands(Symbol(),0,20,2,0,PRICE_CLOSE,MODE_LOWER,1),4));
   bandsUp2=StringToDouble(DoubleToStr(iBands(Symbol(),0,20,2,0,PRICE_CLOSE,MODE_UPPER,2),4));
   bandsLow2=StringToDouble(DoubleToStr(iBands(Symbol(),0,20,2,0,PRICE_CLOSE,MODE_LOWER,2),4));
   bandsMa0=iMA(Symbol(),0,20,0,MODE_SMA,PRICE_CLOSE,0);
   bandsMa1=iMA(Symbol(),0,20,0,MODE_SMA,PRICE_CLOSE,1);
   bandsMa2=iMA(Symbol(),0,20,0,MODE_SMA,PRICE_CLOSE,2);

   rsi0=StringToDouble(DoubleToStr(iRSI(Symbol(),0,7,PRICE_CLOSE,0),0));
   rsi1=StringToDouble(DoubleToStr(iRSI(Symbol(),0,7,PRICE_CLOSE,1),0));

   alligatorTop0=DoubleToStr(iAlligator(NULL,0,13,8,8,5,5,3,MODE_EMA,PRICE_MEDIAN,MODE_GATORJAW,0),5);
   alligatorCenter0=DoubleToStr(iAlligator(NULL,0,13,8,8,5,5,3,MODE_EMA,PRICE_MEDIAN,MODE_GATORTEETH,0),5);
   alligatorBottom0=DoubleToStr(iAlligator(NULL,0,13,8,8,5,5,3,MODE_EMA,PRICE_MEDIAN,MODE_GATORLIPS,0),5);
   alligatorTop1=DoubleToStr(iAlligator(NULL,0,13,8,8,5,5,3,MODE_EMA,PRICE_MEDIAN,MODE_GATORJAW,1),5);
   alligatorCenter1=DoubleToStr(iAlligator(NULL,0,13,8,8,5,5,3,MODE_EMA,PRICE_MEDIAN,MODE_GATORTEETH,1),5);
   alligatorBottom1=DoubleToStr(iAlligator(NULL,0,13,8,8,5,5,3,MODE_EMA,PRICE_MEDIAN,MODE_GATORLIPS,1),5);
   alligatorTop2=DoubleToStr(iAlligator(NULL,0,13,8,8,5,5,3,MODE_EMA,PRICE_MEDIAN,MODE_GATORJAW,2),5);
   alligatorCenter2=DoubleToStr(iAlligator(NULL,0,13,8,8,5,5,3,MODE_EMA,PRICE_MEDIAN,MODE_GATORTEETH,2),5);
   alligatorBottom2=DoubleToStr(iAlligator(NULL,0,13,8,8,5,5,3,MODE_EMA,PRICE_MEDIAN,MODE_GATORLIPS,2),5);

//Print(" 上  ",bands1,"  下   ",bands3);

   CheckForOpen();
   CheckForClose();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {

//string ATRPips =DoubleToStr((iATR(Symbol(),PERIOD_M15,7,0) / Point),5);
//string ATRPrePips1 =DoubleToStr((iATR(Symbol(),PERIOD_M15,7,3) / Point),5);
//string ATRPrePips2 =DoubleToStr((iATR(Symbol(),PERIOD_M15,7,5) / Point),5);

//Print("ATRPips = ",ATRPips,"  ATRPrePips1 = ",ATRPrePips1,"  ATRPrePips2 = ",ATRPrePips2);
//Print("下颚 = ",alligatortop,"  牙齿 = ",alligatorcenter,"  嘴唇 = ",alligatorbotton);

   string macd=DoubleToStr((iMACD(Symbol(),0,12,26,9,PRICE_CLOSE,MODE_MAIN,0)/Point),2);
   string rsi=DoubleToStr(iRSI(Symbol(),0,7,PRICE_CLOSE,0),2);
//Print("MACD:",macd,"  RSI:",rsi);

   if(Bars<30 || IsTradeAllowed()==False)
      return;

   GetWork();
  }
//+------------------------------------------------------------------+
