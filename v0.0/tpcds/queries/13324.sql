
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 182 and 182+10 
             or ss_coupon_amt between 13163 and 13163+1000
             or ss_wholesale_cost between 15 and 15+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 173 and 173+10
          or ss_coupon_amt between 14125 and 14125+1000
          or ss_wholesale_cost between 61 and 61+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 56 and 56+10
          or ss_coupon_amt between 11845 and 11845+1000
          or ss_wholesale_cost between 32 and 32+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 141 and 141+10
          or ss_coupon_amt between 2431 and 2431+1000
          or ss_wholesale_cost between 21 and 21+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 111 and 111+10
          or ss_coupon_amt between 7527 and 7527+1000
          or ss_wholesale_cost between 47 and 47+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 31 and 31+10
          or ss_coupon_amt between 15304 and 15304+1000
          or ss_wholesale_cost between 62 and 62+20)) B6
limit 100;
