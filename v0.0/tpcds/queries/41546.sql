
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 176 and 176+10 
             or ss_coupon_amt between 334 and 334+1000
             or ss_wholesale_cost between 62 and 62+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 180 and 180+10
          or ss_coupon_amt between 15115 and 15115+1000
          or ss_wholesale_cost between 80 and 80+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 26 and 26+10
          or ss_coupon_amt between 14195 and 14195+1000
          or ss_wholesale_cost between 32 and 32+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 140 and 140+10
          or ss_coupon_amt between 2025 and 2025+1000
          or ss_wholesale_cost between 23 and 23+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 50 and 50+10
          or ss_coupon_amt between 9568 and 9568+1000
          or ss_wholesale_cost between 33 and 33+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 158 and 158+10
          or ss_coupon_amt between 1749 and 1749+1000
          or ss_wholesale_cost between 16 and 16+20)) B6
limit 100;
