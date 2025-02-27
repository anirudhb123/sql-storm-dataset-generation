
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 149 and 149+10 
             or ss_coupon_amt between 2697 and 2697+1000
             or ss_wholesale_cost between 40 and 40+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 35 and 35+10
          or ss_coupon_amt between 11970 and 11970+1000
          or ss_wholesale_cost between 22 and 22+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 129 and 129+10
          or ss_coupon_amt between 13832 and 13832+1000
          or ss_wholesale_cost between 38 and 38+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 48 and 48+10
          or ss_coupon_amt between 4153 and 4153+1000
          or ss_wholesale_cost between 55 and 55+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 53 and 53+10
          or ss_coupon_amt between 4433 and 4433+1000
          or ss_wholesale_cost between 42 and 42+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 170 and 170+10
          or ss_coupon_amt between 9855 and 9855+1000
          or ss_wholesale_cost between 4 and 4+20)) B6
limit 100;
