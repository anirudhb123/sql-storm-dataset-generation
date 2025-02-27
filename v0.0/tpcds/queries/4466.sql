
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 8 and 8+10 
             or ss_coupon_amt between 6198 and 6198+1000
             or ss_wholesale_cost between 33 and 33+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 75 and 75+10
          or ss_coupon_amt between 3801 and 3801+1000
          or ss_wholesale_cost between 1 and 1+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 185 and 185+10
          or ss_coupon_amt between 1216 and 1216+1000
          or ss_wholesale_cost between 43 and 43+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 166 and 166+10
          or ss_coupon_amt between 6519 and 6519+1000
          or ss_wholesale_cost between 75 and 75+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 2 and 2+10
          or ss_coupon_amt between 2032 and 2032+1000
          or ss_wholesale_cost between 20 and 20+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 131 and 131+10
          or ss_coupon_amt between 1672 and 1672+1000
          or ss_wholesale_cost between 27 and 27+20)) B6
limit 100;
