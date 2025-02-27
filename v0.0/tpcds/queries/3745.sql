
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 55 and 55+10 
             or ss_coupon_amt between 6070 and 6070+1000
             or ss_wholesale_cost between 11 and 11+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 149 and 149+10
          or ss_coupon_amt between 2111 and 2111+1000
          or ss_wholesale_cost between 29 and 29+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 148 and 148+10
          or ss_coupon_amt between 3983 and 3983+1000
          or ss_wholesale_cost between 28 and 28+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 39 and 39+10
          or ss_coupon_amt between 8816 and 8816+1000
          or ss_wholesale_cost between 65 and 65+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 120 and 120+10
          or ss_coupon_amt between 12917 and 12917+1000
          or ss_wholesale_cost between 52 and 52+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 52 and 52+10
          or ss_coupon_amt between 261 and 261+1000
          or ss_wholesale_cost between 61 and 61+20)) B6
limit 100;
