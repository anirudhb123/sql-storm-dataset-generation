
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 135 and 135+10 
             or ss_coupon_amt between 1778 and 1778+1000
             or ss_wholesale_cost between 10 and 10+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 0 and 0+10
          or ss_coupon_amt between 8559 and 8559+1000
          or ss_wholesale_cost between 76 and 76+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 63 and 63+10
          or ss_coupon_amt between 5809 and 5809+1000
          or ss_wholesale_cost between 4 and 4+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 71 and 71+10
          or ss_coupon_amt between 17246 and 17246+1000
          or ss_wholesale_cost between 16 and 16+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 64 and 64+10
          or ss_coupon_amt between 1472 and 1472+1000
          or ss_wholesale_cost between 55 and 55+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 99 and 99+10
          or ss_coupon_amt between 8610 and 8610+1000
          or ss_wholesale_cost between 32 and 32+20)) B6
limit 100;
