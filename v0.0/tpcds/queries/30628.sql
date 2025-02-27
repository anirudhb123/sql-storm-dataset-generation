
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 36 and 36+10 
             or ss_coupon_amt between 5029 and 5029+1000
             or ss_wholesale_cost between 74 and 74+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 27 and 27+10
          or ss_coupon_amt between 1654 and 1654+1000
          or ss_wholesale_cost between 7 and 7+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 28 and 28+10
          or ss_coupon_amt between 15232 and 15232+1000
          or ss_wholesale_cost between 69 and 69+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 97 and 97+10
          or ss_coupon_amt between 11183 and 11183+1000
          or ss_wholesale_cost between 49 and 49+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 158 and 158+10
          or ss_coupon_amt between 14873 and 14873+1000
          or ss_wholesale_cost between 5 and 5+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 165 and 165+10
          or ss_coupon_amt between 10833 and 10833+1000
          or ss_wholesale_cost between 42 and 42+20)) B6
limit 100;
