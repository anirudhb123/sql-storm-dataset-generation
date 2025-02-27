
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 88 and 88+10 
             or ss_coupon_amt between 6815 and 6815+1000
             or ss_wholesale_cost between 9 and 9+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 190 and 190+10
          or ss_coupon_amt between 12760 and 12760+1000
          or ss_wholesale_cost between 16 and 16+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 67 and 67+10
          or ss_coupon_amt between 16176 and 16176+1000
          or ss_wholesale_cost between 59 and 59+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 154 and 154+10
          or ss_coupon_amt between 6087 and 6087+1000
          or ss_wholesale_cost between 70 and 70+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 172 and 172+10
          or ss_coupon_amt between 1596 and 1596+1000
          or ss_wholesale_cost between 37 and 37+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 63 and 63+10
          or ss_coupon_amt between 794 and 794+1000
          or ss_wholesale_cost between 62 and 62+20)) B6
limit 100;
