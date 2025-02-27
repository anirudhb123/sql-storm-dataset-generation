
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 82 and 82+10 
             or ss_coupon_amt between 13022 and 13022+1000
             or ss_wholesale_cost between 37 and 37+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 178 and 178+10
          or ss_coupon_amt between 16219 and 16219+1000
          or ss_wholesale_cost between 38 and 38+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 111 and 111+10
          or ss_coupon_amt between 17376 and 17376+1000
          or ss_wholesale_cost between 9 and 9+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 41 and 41+10
          or ss_coupon_amt between 3786 and 3786+1000
          or ss_wholesale_cost between 46 and 46+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 38 and 38+10
          or ss_coupon_amt between 7079 and 7079+1000
          or ss_wholesale_cost between 62 and 62+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 181 and 181+10
          or ss_coupon_amt between 15832 and 15832+1000
          or ss_wholesale_cost between 64 and 64+20)) B6
limit 100;
