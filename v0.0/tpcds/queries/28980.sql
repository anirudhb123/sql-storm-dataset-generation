
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 51 and 51+10 
             or ss_coupon_amt between 10899 and 10899+1000
             or ss_wholesale_cost between 16 and 16+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 5 and 5+10
          or ss_coupon_amt between 8161 and 8161+1000
          or ss_wholesale_cost between 21 and 21+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 135 and 135+10
          or ss_coupon_amt between 62 and 62+1000
          or ss_wholesale_cost between 51 and 51+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 24 and 24+10
          or ss_coupon_amt between 13950 and 13950+1000
          or ss_wholesale_cost between 34 and 34+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 70 and 70+10
          or ss_coupon_amt between 8107 and 8107+1000
          or ss_wholesale_cost between 8 and 8+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 149 and 149+10
          or ss_coupon_amt between 7259 and 7259+1000
          or ss_wholesale_cost between 7 and 7+20)) B6
limit 100;
