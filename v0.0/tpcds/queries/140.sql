
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 164 and 164+10 
             or ss_coupon_amt between 9264 and 9264+1000
             or ss_wholesale_cost between 20 and 20+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 131 and 131+10
          or ss_coupon_amt between 1589 and 1589+1000
          or ss_wholesale_cost between 53 and 53+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 40 and 40+10
          or ss_coupon_amt between 3251 and 3251+1000
          or ss_wholesale_cost between 7 and 7+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 30 and 30+10
          or ss_coupon_amt between 5598 and 5598+1000
          or ss_wholesale_cost between 66 and 66+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 113 and 113+10
          or ss_coupon_amt between 13821 and 13821+1000
          or ss_wholesale_cost between 10 and 10+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 136 and 136+10
          or ss_coupon_amt between 4178 and 4178+1000
          or ss_wholesale_cost between 6 and 6+20)) B6
limit 100;
