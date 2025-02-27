
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 84 and 84+10 
             or ss_coupon_amt between 3939 and 3939+1000
             or ss_wholesale_cost between 31 and 31+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 57 and 57+10
          or ss_coupon_amt between 10255 and 10255+1000
          or ss_wholesale_cost between 47 and 47+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 94 and 94+10
          or ss_coupon_amt between 6809 and 6809+1000
          or ss_wholesale_cost between 21 and 21+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 23 and 23+10
          or ss_coupon_amt between 8326 and 8326+1000
          or ss_wholesale_cost between 63 and 63+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 54 and 54+10
          or ss_coupon_amt between 11824 and 11824+1000
          or ss_wholesale_cost between 4 and 4+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 18 and 18+10
          or ss_coupon_amt between 12510 and 12510+1000
          or ss_wholesale_cost between 14 and 14+20)) B6
limit 100;
