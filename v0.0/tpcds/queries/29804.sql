
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 25 and 25+10 
             or ss_coupon_amt between 7735 and 7735+1000
             or ss_wholesale_cost between 10 and 10+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 14 and 14+10
          or ss_coupon_amt between 14824 and 14824+1000
          or ss_wholesale_cost between 62 and 62+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 69 and 69+10
          or ss_coupon_amt between 10919 and 10919+1000
          or ss_wholesale_cost between 28 and 28+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 46 and 46+10
          or ss_coupon_amt between 8019 and 8019+1000
          or ss_wholesale_cost between 19 and 19+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 80 and 80+10
          or ss_coupon_amt between 6007 and 6007+1000
          or ss_wholesale_cost between 65 and 65+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 73 and 73+10
          or ss_coupon_amt between 1861 and 1861+1000
          or ss_wholesale_cost between 34 and 34+20)) B6
limit 100;
