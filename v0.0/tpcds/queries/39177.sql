
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 122 and 122+10 
             or ss_coupon_amt between 15231 and 15231+1000
             or ss_wholesale_cost between 3 and 3+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 141 and 141+10
          or ss_coupon_amt between 8815 and 8815+1000
          or ss_wholesale_cost between 13 and 13+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 46 and 46+10
          or ss_coupon_amt between 6506 and 6506+1000
          or ss_wholesale_cost between 59 and 59+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 37 and 37+10
          or ss_coupon_amt between 5571 and 5571+1000
          or ss_wholesale_cost between 62 and 62+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 75 and 75+10
          or ss_coupon_amt between 5217 and 5217+1000
          or ss_wholesale_cost between 10 and 10+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 30 and 30+10
          or ss_coupon_amt between 8589 and 8589+1000
          or ss_wholesale_cost between 42 and 42+20)) B6
limit 100;
