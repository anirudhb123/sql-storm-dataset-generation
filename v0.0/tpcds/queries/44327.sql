
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 27 and 27+10 
             or ss_coupon_amt between 1015 and 1015+1000
             or ss_wholesale_cost between 6 and 6+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 76 and 76+10
          or ss_coupon_amt between 1819 and 1819+1000
          or ss_wholesale_cost between 12 and 12+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 176 and 176+10
          or ss_coupon_amt between 12634 and 12634+1000
          or ss_wholesale_cost between 16 and 16+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 184 and 184+10
          or ss_coupon_amt between 2999 and 2999+1000
          or ss_wholesale_cost between 76 and 76+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 57 and 57+10
          or ss_coupon_amt between 5208 and 5208+1000
          or ss_wholesale_cost between 23 and 23+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 17 and 17+10
          or ss_coupon_amt between 12190 and 12190+1000
          or ss_wholesale_cost between 24 and 24+20)) B6
limit 100;
