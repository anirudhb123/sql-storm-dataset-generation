
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 81 and 81+10 
             or ss_coupon_amt between 17879 and 17879+1000
             or ss_wholesale_cost between 29 and 29+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 127 and 127+10
          or ss_coupon_amt between 3753 and 3753+1000
          or ss_wholesale_cost between 77 and 77+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 106 and 106+10
          or ss_coupon_amt between 11593 and 11593+1000
          or ss_wholesale_cost between 15 and 15+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 124 and 124+10
          or ss_coupon_amt between 13070 and 13070+1000
          or ss_wholesale_cost between 54 and 54+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 74 and 74+10
          or ss_coupon_amt between 305 and 305+1000
          or ss_wholesale_cost between 6 and 6+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 178 and 178+10
          or ss_coupon_amt between 1900 and 1900+1000
          or ss_wholesale_cost between 41 and 41+20)) B6
limit 100;
