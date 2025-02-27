
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 0 and 0+10 
             or ss_coupon_amt between 6843 and 6843+1000
             or ss_wholesale_cost between 69 and 69+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 5 and 5+10
          or ss_coupon_amt between 9475 and 9475+1000
          or ss_wholesale_cost between 26 and 26+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 167 and 167+10
          or ss_coupon_amt between 1625 and 1625+1000
          or ss_wholesale_cost between 5 and 5+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 39 and 39+10
          or ss_coupon_amt between 16061 and 16061+1000
          or ss_wholesale_cost between 3 and 3+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 60 and 60+10
          or ss_coupon_amt between 6706 and 6706+1000
          or ss_wholesale_cost between 50 and 50+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 151 and 151+10
          or ss_coupon_amt between 12654 and 12654+1000
          or ss_wholesale_cost between 33 and 33+20)) B6
limit 100;
