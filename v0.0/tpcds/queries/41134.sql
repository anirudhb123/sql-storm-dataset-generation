
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 166 and 166+10 
             or ss_coupon_amt between 10535 and 10535+1000
             or ss_wholesale_cost between 40 and 40+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 3 and 3+10
          or ss_coupon_amt between 14204 and 14204+1000
          or ss_wholesale_cost between 64 and 64+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 38 and 38+10
          or ss_coupon_amt between 11278 and 11278+1000
          or ss_wholesale_cost between 19 and 19+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 54 and 54+10
          or ss_coupon_amt between 1044 and 1044+1000
          or ss_wholesale_cost between 4 and 4+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 126 and 126+10
          or ss_coupon_amt between 5974 and 5974+1000
          or ss_wholesale_cost between 76 and 76+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 98 and 98+10
          or ss_coupon_amt between 11507 and 11507+1000
          or ss_wholesale_cost between 45 and 45+20)) B6
limit 100;
