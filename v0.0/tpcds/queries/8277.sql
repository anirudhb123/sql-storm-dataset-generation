
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 76 and 76+10 
             or ss_coupon_amt between 11918 and 11918+1000
             or ss_wholesale_cost between 66 and 66+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 115 and 115+10
          or ss_coupon_amt between 14465 and 14465+1000
          or ss_wholesale_cost between 19 and 19+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 112 and 112+10
          or ss_coupon_amt between 223 and 223+1000
          or ss_wholesale_cost between 79 and 79+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 117 and 117+10
          or ss_coupon_amt between 6686 and 6686+1000
          or ss_wholesale_cost between 54 and 54+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 190 and 190+10
          or ss_coupon_amt between 15059 and 15059+1000
          or ss_wholesale_cost between 57 and 57+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 32 and 32+10
          or ss_coupon_amt between 4543 and 4543+1000
          or ss_wholesale_cost between 52 and 52+20)) B6
limit 100;
