
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 38 and 38+10 
             or ss_coupon_amt between 6991 and 6991+1000
             or ss_wholesale_cost between 20 and 20+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 111 and 111+10
          or ss_coupon_amt between 2667 and 2667+1000
          or ss_wholesale_cost between 40 and 40+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 72 and 72+10
          or ss_coupon_amt between 1744 and 1744+1000
          or ss_wholesale_cost between 64 and 64+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 97 and 97+10
          or ss_coupon_amt between 12264 and 12264+1000
          or ss_wholesale_cost between 34 and 34+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 149 and 149+10
          or ss_coupon_amt between 2934 and 2934+1000
          or ss_wholesale_cost between 23 and 23+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 60 and 60+10
          or ss_coupon_amt between 243 and 243+1000
          or ss_wholesale_cost between 22 and 22+20)) B6
limit 100;
