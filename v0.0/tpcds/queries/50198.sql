
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 79 and 79+10 
             or ss_coupon_amt between 4579 and 4579+1000
             or ss_wholesale_cost between 13 and 13+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 176 and 176+10
          or ss_coupon_amt between 9899 and 9899+1000
          or ss_wholesale_cost between 7 and 7+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 134 and 134+10
          or ss_coupon_amt between 8949 and 8949+1000
          or ss_wholesale_cost between 75 and 75+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 45 and 45+10
          or ss_coupon_amt between 6371 and 6371+1000
          or ss_wholesale_cost between 41 and 41+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 71 and 71+10
          or ss_coupon_amt between 13069 and 13069+1000
          or ss_wholesale_cost between 63 and 63+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 178 and 178+10
          or ss_coupon_amt between 1589 and 1589+1000
          or ss_wholesale_cost between 36 and 36+20)) B6
limit 100;
