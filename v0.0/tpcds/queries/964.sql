
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 86 and 86+10 
             or ss_coupon_amt between 8098 and 8098+1000
             or ss_wholesale_cost between 54 and 54+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 129 and 129+10
          or ss_coupon_amt between 1601 and 1601+1000
          or ss_wholesale_cost between 29 and 29+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 91 and 91+10
          or ss_coupon_amt between 11795 and 11795+1000
          or ss_wholesale_cost between 65 and 65+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 153 and 153+10
          or ss_coupon_amt between 8898 and 8898+1000
          or ss_wholesale_cost between 76 and 76+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 169 and 169+10
          or ss_coupon_amt between 10856 and 10856+1000
          or ss_wholesale_cost between 35 and 35+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 58 and 58+10
          or ss_coupon_amt between 4144 and 4144+1000
          or ss_wholesale_cost between 1 and 1+20)) B6
limit 100;
