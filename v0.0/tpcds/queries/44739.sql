
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 25 and 25+10 
             or ss_coupon_amt between 11175 and 11175+1000
             or ss_wholesale_cost between 18 and 18+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 51 and 51+10
          or ss_coupon_amt between 13235 and 13235+1000
          or ss_wholesale_cost between 52 and 52+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 163 and 163+10
          or ss_coupon_amt between 13362 and 13362+1000
          or ss_wholesale_cost between 77 and 77+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 69 and 69+10
          or ss_coupon_amt between 1621 and 1621+1000
          or ss_wholesale_cost between 27 and 27+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 145 and 145+10
          or ss_coupon_amt between 10536 and 10536+1000
          or ss_wholesale_cost between 32 and 32+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 130 and 130+10
          or ss_coupon_amt between 13178 and 13178+1000
          or ss_wholesale_cost between 5 and 5+20)) B6
limit 100;
