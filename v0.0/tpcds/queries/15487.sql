
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 80 and 80+10 
             or ss_coupon_amt between 13547 and 13547+1000
             or ss_wholesale_cost between 65 and 65+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 143 and 143+10
          or ss_coupon_amt between 2971 and 2971+1000
          or ss_wholesale_cost between 63 and 63+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 48 and 48+10
          or ss_coupon_amt between 10589 and 10589+1000
          or ss_wholesale_cost between 68 and 68+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 150 and 150+10
          or ss_coupon_amt between 3762 and 3762+1000
          or ss_wholesale_cost between 9 and 9+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 32 and 32+10
          or ss_coupon_amt between 11012 and 11012+1000
          or ss_wholesale_cost between 73 and 73+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 78 and 78+10
          or ss_coupon_amt between 4287 and 4287+1000
          or ss_wholesale_cost between 28 and 28+20)) B6
limit 100;
