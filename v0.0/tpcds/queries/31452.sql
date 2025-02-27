
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 147 and 147+10 
             or ss_coupon_amt between 4308 and 4308+1000
             or ss_wholesale_cost between 22 and 22+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 144 and 144+10
          or ss_coupon_amt between 8234 and 8234+1000
          or ss_wholesale_cost between 4 and 4+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 57 and 57+10
          or ss_coupon_amt between 6838 and 6838+1000
          or ss_wholesale_cost between 46 and 46+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 8 and 8+10
          or ss_coupon_amt between 12518 and 12518+1000
          or ss_wholesale_cost between 37 and 37+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 9 and 9+10
          or ss_coupon_amt between 1156 and 1156+1000
          or ss_wholesale_cost between 17 and 17+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 24 and 24+10
          or ss_coupon_amt between 16578 and 16578+1000
          or ss_wholesale_cost between 80 and 80+20)) B6
limit 100;
