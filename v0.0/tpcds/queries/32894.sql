
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 48 and 48+10 
             or ss_coupon_amt between 10457 and 10457+1000
             or ss_wholesale_cost between 72 and 72+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 6 and 6+10
          or ss_coupon_amt between 5072 and 5072+1000
          or ss_wholesale_cost between 33 and 33+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 107 and 107+10
          or ss_coupon_amt between 5562 and 5562+1000
          or ss_wholesale_cost between 50 and 50+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 170 and 170+10
          or ss_coupon_amt between 1075 and 1075+1000
          or ss_wholesale_cost between 11 and 11+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 98 and 98+10
          or ss_coupon_amt between 11093 and 11093+1000
          or ss_wholesale_cost between 77 and 77+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 123 and 123+10
          or ss_coupon_amt between 7377 and 7377+1000
          or ss_wholesale_cost between 38 and 38+20)) B6
limit 100;
