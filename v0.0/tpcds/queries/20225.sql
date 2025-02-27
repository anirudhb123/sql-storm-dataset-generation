
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 176 and 176+10 
             or ss_coupon_amt between 6474 and 6474+1000
             or ss_wholesale_cost between 41 and 41+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 163 and 163+10
          or ss_coupon_amt between 434 and 434+1000
          or ss_wholesale_cost between 15 and 15+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 77 and 77+10
          or ss_coupon_amt between 841 and 841+1000
          or ss_wholesale_cost between 55 and 55+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 39 and 39+10
          or ss_coupon_amt between 8753 and 8753+1000
          or ss_wholesale_cost between 39 and 39+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 116 and 116+10
          or ss_coupon_amt between 7364 and 7364+1000
          or ss_wholesale_cost between 57 and 57+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 154 and 154+10
          or ss_coupon_amt between 2336 and 2336+1000
          or ss_wholesale_cost between 9 and 9+20)) B6
limit 100;
