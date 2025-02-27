
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 32 and 32+10 
             or ss_coupon_amt between 8891 and 8891+1000
             or ss_wholesale_cost between 33 and 33+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 118 and 118+10
          or ss_coupon_amt between 10129 and 10129+1000
          or ss_wholesale_cost between 4 and 4+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 120 and 120+10
          or ss_coupon_amt between 489 and 489+1000
          or ss_wholesale_cost between 74 and 74+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 123 and 123+10
          or ss_coupon_amt between 2219 and 2219+1000
          or ss_wholesale_cost between 16 and 16+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 61 and 61+10
          or ss_coupon_amt between 5051 and 5051+1000
          or ss_wholesale_cost between 19 and 19+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 96 and 96+10
          or ss_coupon_amt between 2242 and 2242+1000
          or ss_wholesale_cost between 68 and 68+20)) B6
limit 100;
