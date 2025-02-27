
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 145 and 145+10 
             or ss_coupon_amt between 6458 and 6458+1000
             or ss_wholesale_cost between 27 and 27+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 24 and 24+10
          or ss_coupon_amt between 9484 and 9484+1000
          or ss_wholesale_cost between 56 and 56+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 83 and 83+10
          or ss_coupon_amt between 5104 and 5104+1000
          or ss_wholesale_cost between 1 and 1+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 79 and 79+10
          or ss_coupon_amt between 2240 and 2240+1000
          or ss_wholesale_cost between 44 and 44+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 36 and 36+10
          or ss_coupon_amt between 10505 and 10505+1000
          or ss_wholesale_cost between 15 and 15+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 76 and 76+10
          or ss_coupon_amt between 13169 and 13169+1000
          or ss_wholesale_cost between 39 and 39+20)) B6
limit 100;
