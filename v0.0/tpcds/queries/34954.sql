
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 169 and 169+10 
             or ss_coupon_amt between 15514 and 15514+1000
             or ss_wholesale_cost between 17 and 17+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 81 and 81+10
          or ss_coupon_amt between 8778 and 8778+1000
          or ss_wholesale_cost between 7 and 7+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 18 and 18+10
          or ss_coupon_amt between 11404 and 11404+1000
          or ss_wholesale_cost between 35 and 35+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 52 and 52+10
          or ss_coupon_amt between 13922 and 13922+1000
          or ss_wholesale_cost between 15 and 15+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 67 and 67+10
          or ss_coupon_amt between 2176 and 2176+1000
          or ss_wholesale_cost between 13 and 13+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 103 and 103+10
          or ss_coupon_amt between 2659 and 2659+1000
          or ss_wholesale_cost between 41 and 41+20)) B6
limit 100;
