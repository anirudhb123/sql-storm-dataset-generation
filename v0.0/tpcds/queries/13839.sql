
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 9 and 9+10 
             or ss_coupon_amt between 7862 and 7862+1000
             or ss_wholesale_cost between 3 and 3+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 135 and 135+10
          or ss_coupon_amt between 6223 and 6223+1000
          or ss_wholesale_cost between 58 and 58+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 46 and 46+10
          or ss_coupon_amt between 1963 and 1963+1000
          or ss_wholesale_cost between 26 and 26+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 165 and 165+10
          or ss_coupon_amt between 12494 and 12494+1000
          or ss_wholesale_cost between 57 and 57+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 36 and 36+10
          or ss_coupon_amt between 7793 and 7793+1000
          or ss_wholesale_cost between 29 and 29+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 117 and 117+10
          or ss_coupon_amt between 7571 and 7571+1000
          or ss_wholesale_cost between 4 and 4+20)) B6
limit 100;
