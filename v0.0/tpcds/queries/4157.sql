
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 83 and 83+10 
             or ss_coupon_amt between 6093 and 6093+1000
             or ss_wholesale_cost between 66 and 66+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 86 and 86+10
          or ss_coupon_amt between 8660 and 8660+1000
          or ss_wholesale_cost between 7 and 7+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 56 and 56+10
          or ss_coupon_amt between 4710 and 4710+1000
          or ss_wholesale_cost between 76 and 76+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 149 and 149+10
          or ss_coupon_amt between 2801 and 2801+1000
          or ss_wholesale_cost between 43 and 43+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 28 and 28+10
          or ss_coupon_amt between 3529 and 3529+1000
          or ss_wholesale_cost between 35 and 35+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 188 and 188+10
          or ss_coupon_amt between 12404 and 12404+1000
          or ss_wholesale_cost between 61 and 61+20)) B6
limit 100;
