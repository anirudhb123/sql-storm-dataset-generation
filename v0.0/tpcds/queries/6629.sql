
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 122 and 122+10 
             or ss_coupon_amt between 6582 and 6582+1000
             or ss_wholesale_cost between 8 and 8+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 12 and 12+10
          or ss_coupon_amt between 5152 and 5152+1000
          or ss_wholesale_cost between 78 and 78+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 14 and 14+10
          or ss_coupon_amt between 5923 and 5923+1000
          or ss_wholesale_cost between 5 and 5+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 71 and 71+10
          or ss_coupon_amt between 10853 and 10853+1000
          or ss_wholesale_cost between 71 and 71+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 23 and 23+10
          or ss_coupon_amt between 3764 and 3764+1000
          or ss_wholesale_cost between 37 and 37+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 51 and 51+10
          or ss_coupon_amt between 7827 and 7827+1000
          or ss_wholesale_cost between 52 and 52+20)) B6
limit 100;
