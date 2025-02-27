
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 112 and 112+10 
             or ss_coupon_amt between 17347 and 17347+1000
             or ss_wholesale_cost between 4 and 4+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 102 and 102+10
          or ss_coupon_amt between 6028 and 6028+1000
          or ss_wholesale_cost between 77 and 77+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 161 and 161+10
          or ss_coupon_amt between 9625 and 9625+1000
          or ss_wholesale_cost between 72 and 72+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 70 and 70+10
          or ss_coupon_amt between 6178 and 6178+1000
          or ss_wholesale_cost between 59 and 59+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 10 and 10+10
          or ss_coupon_amt between 5079 and 5079+1000
          or ss_wholesale_cost between 26 and 26+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 1 and 1+10
          or ss_coupon_amt between 8720 and 8720+1000
          or ss_wholesale_cost between 20 and 20+20)) B6
limit 100;
