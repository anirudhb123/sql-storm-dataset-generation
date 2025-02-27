
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 135 and 135+10 
             or ss_coupon_amt between 3129 and 3129+1000
             or ss_wholesale_cost between 2 and 2+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 168 and 168+10
          or ss_coupon_amt between 10724 and 10724+1000
          or ss_wholesale_cost between 14 and 14+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 87 and 87+10
          or ss_coupon_amt between 188 and 188+1000
          or ss_wholesale_cost between 38 and 38+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 175 and 175+10
          or ss_coupon_amt between 6754 and 6754+1000
          or ss_wholesale_cost between 52 and 52+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 77 and 77+10
          or ss_coupon_amt between 7518 and 7518+1000
          or ss_wholesale_cost between 57 and 57+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 19 and 19+10
          or ss_coupon_amt between 16136 and 16136+1000
          or ss_wholesale_cost between 35 and 35+20)) B6
limit 100;
