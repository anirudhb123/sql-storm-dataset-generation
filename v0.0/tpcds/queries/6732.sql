
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 112 and 112+10 
             or ss_coupon_amt between 5870 and 5870+1000
             or ss_wholesale_cost between 9 and 9+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 56 and 56+10
          or ss_coupon_amt between 7399 and 7399+1000
          or ss_wholesale_cost between 79 and 79+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 73 and 73+10
          or ss_coupon_amt between 7364 and 7364+1000
          or ss_wholesale_cost between 15 and 15+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 69 and 69+10
          or ss_coupon_amt between 7474 and 7474+1000
          or ss_wholesale_cost between 16 and 16+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 163 and 163+10
          or ss_coupon_amt between 7517 and 7517+1000
          or ss_wholesale_cost between 70 and 70+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 1 and 1+10
          or ss_coupon_amt between 8288 and 8288+1000
          or ss_wholesale_cost between 26 and 26+20)) B6
limit 100;
