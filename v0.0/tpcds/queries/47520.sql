
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 27 and 27+10 
             or ss_coupon_amt between 11558 and 11558+1000
             or ss_wholesale_cost between 78 and 78+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 48 and 48+10
          or ss_coupon_amt between 2243 and 2243+1000
          or ss_wholesale_cost between 72 and 72+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 26 and 26+10
          or ss_coupon_amt between 4118 and 4118+1000
          or ss_wholesale_cost between 71 and 71+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 189 and 189+10
          or ss_coupon_amt between 16762 and 16762+1000
          or ss_wholesale_cost between 40 and 40+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 152 and 152+10
          or ss_coupon_amt between 5994 and 5994+1000
          or ss_wholesale_cost between 31 and 31+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 106 and 106+10
          or ss_coupon_amt between 12782 and 12782+1000
          or ss_wholesale_cost between 35 and 35+20)) B6
limit 100;
