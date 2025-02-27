
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 138 and 138+10 
             or ss_coupon_amt between 4640 and 4640+1000
             or ss_wholesale_cost between 9 and 9+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 101 and 101+10
          or ss_coupon_amt between 4319 and 4319+1000
          or ss_wholesale_cost between 11 and 11+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 36 and 36+10
          or ss_coupon_amt between 2503 and 2503+1000
          or ss_wholesale_cost between 50 and 50+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 67 and 67+10
          or ss_coupon_amt between 12832 and 12832+1000
          or ss_wholesale_cost between 42 and 42+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 9 and 9+10
          or ss_coupon_amt between 12424 and 12424+1000
          or ss_wholesale_cost between 63 and 63+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 3 and 3+10
          or ss_coupon_amt between 1349 and 1349+1000
          or ss_wholesale_cost between 64 and 64+20)) B6
limit 100;
