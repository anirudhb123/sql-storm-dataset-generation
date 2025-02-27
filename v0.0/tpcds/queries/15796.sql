
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 41 and 41+10 
             or ss_coupon_amt between 14147 and 14147+1000
             or ss_wholesale_cost between 21 and 21+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 102 and 102+10
          or ss_coupon_amt between 8271 and 8271+1000
          or ss_wholesale_cost between 38 and 38+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 143 and 143+10
          or ss_coupon_amt between 12881 and 12881+1000
          or ss_wholesale_cost between 63 and 63+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 63 and 63+10
          or ss_coupon_amt between 1330 and 1330+1000
          or ss_wholesale_cost between 13 and 13+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 168 and 168+10
          or ss_coupon_amt between 3198 and 3198+1000
          or ss_wholesale_cost between 42 and 42+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 87 and 87+10
          or ss_coupon_amt between 9288 and 9288+1000
          or ss_wholesale_cost between 28 and 28+20)) B6
limit 100;
