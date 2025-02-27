
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 22 and 22+10 
             or ss_coupon_amt between 13075 and 13075+1000
             or ss_wholesale_cost between 45 and 45+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 134 and 134+10
          or ss_coupon_amt between 11989 and 11989+1000
          or ss_wholesale_cost between 68 and 68+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 10 and 10+10
          or ss_coupon_amt between 10706 and 10706+1000
          or ss_wholesale_cost between 55 and 55+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 152 and 152+10
          or ss_coupon_amt between 10554 and 10554+1000
          or ss_wholesale_cost between 18 and 18+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 98 and 98+10
          or ss_coupon_amt between 1739 and 1739+1000
          or ss_wholesale_cost between 8 and 8+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 177 and 177+10
          or ss_coupon_amt between 22 and 22+1000
          or ss_wholesale_cost between 29 and 29+20)) B6
limit 100;
