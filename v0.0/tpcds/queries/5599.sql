
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 94 and 94+10 
             or ss_coupon_amt between 14917 and 14917+1000
             or ss_wholesale_cost between 19 and 19+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 79 and 79+10
          or ss_coupon_amt between 4910 and 4910+1000
          or ss_wholesale_cost between 30 and 30+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 13 and 13+10
          or ss_coupon_amt between 12177 and 12177+1000
          or ss_wholesale_cost between 52 and 52+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 22 and 22+10
          or ss_coupon_amt between 15229 and 15229+1000
          or ss_wholesale_cost between 22 and 22+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 44 and 44+10
          or ss_coupon_amt between 1009 and 1009+1000
          or ss_wholesale_cost between 54 and 54+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 81 and 81+10
          or ss_coupon_amt between 5292 and 5292+1000
          or ss_wholesale_cost between 74 and 74+20)) B6
limit 100;
