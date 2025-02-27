
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 62 and 62+10 
             or ss_coupon_amt between 17501 and 17501+1000
             or ss_wholesale_cost between 54 and 54+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 64 and 64+10
          or ss_coupon_amt between 16581 and 16581+1000
          or ss_wholesale_cost between 19 and 19+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 49 and 49+10
          or ss_coupon_amt between 10644 and 10644+1000
          or ss_wholesale_cost between 55 and 55+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 163 and 163+10
          or ss_coupon_amt between 14774 and 14774+1000
          or ss_wholesale_cost between 1 and 1+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 128 and 128+10
          or ss_coupon_amt between 8070 and 8070+1000
          or ss_wholesale_cost between 14 and 14+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 79 and 79+10
          or ss_coupon_amt between 10359 and 10359+1000
          or ss_wholesale_cost between 21 and 21+20)) B6
limit 100;
