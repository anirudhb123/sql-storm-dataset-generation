
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 154 and 154+10 
             or ss_coupon_amt between 16875 and 16875+1000
             or ss_wholesale_cost between 17 and 17+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 13 and 13+10
          or ss_coupon_amt between 11190 and 11190+1000
          or ss_wholesale_cost between 66 and 66+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 48 and 48+10
          or ss_coupon_amt between 2768 and 2768+1000
          or ss_wholesale_cost between 12 and 12+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 27 and 27+10
          or ss_coupon_amt between 8264 and 8264+1000
          or ss_wholesale_cost between 48 and 48+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 39 and 39+10
          or ss_coupon_amt between 4149 and 4149+1000
          or ss_wholesale_cost between 38 and 38+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 43 and 43+10
          or ss_coupon_amt between 6868 and 6868+1000
          or ss_wholesale_cost between 16 and 16+20)) B6
limit 100;
