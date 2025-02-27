
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 158 and 158+10 
             or ss_coupon_amt between 366 and 366+1000
             or ss_wholesale_cost between 10 and 10+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 188 and 188+10
          or ss_coupon_amt between 12391 and 12391+1000
          or ss_wholesale_cost between 2 and 2+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 75 and 75+10
          or ss_coupon_amt between 980 and 980+1000
          or ss_wholesale_cost between 37 and 37+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 61 and 61+10
          or ss_coupon_amt between 13417 and 13417+1000
          or ss_wholesale_cost between 41 and 41+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 131 and 131+10
          or ss_coupon_amt between 12305 and 12305+1000
          or ss_wholesale_cost between 51 and 51+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 156 and 156+10
          or ss_coupon_amt between 3377 and 3377+1000
          or ss_wholesale_cost between 68 and 68+20)) B6
limit 100;
