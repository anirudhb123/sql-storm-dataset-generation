
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 12 and 12+10 
             or ss_coupon_amt between 12381 and 12381+1000
             or ss_wholesale_cost between 75 and 75+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 109 and 109+10
          or ss_coupon_amt between 1693 and 1693+1000
          or ss_wholesale_cost between 26 and 26+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 56 and 56+10
          or ss_coupon_amt between 17406 and 17406+1000
          or ss_wholesale_cost between 45 and 45+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 142 and 142+10
          or ss_coupon_amt between 2371 and 2371+1000
          or ss_wholesale_cost between 17 and 17+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 189 and 189+10
          or ss_coupon_amt between 269 and 269+1000
          or ss_wholesale_cost between 8 and 8+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 176 and 176+10
          or ss_coupon_amt between 6544 and 6544+1000
          or ss_wholesale_cost between 24 and 24+20)) B6
limit 100;
