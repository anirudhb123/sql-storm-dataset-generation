
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 122 and 122+10 
             or ss_coupon_amt between 12179 and 12179+1000
             or ss_wholesale_cost between 79 and 79+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 10 and 10+10
          or ss_coupon_amt between 11064 and 11064+1000
          or ss_wholesale_cost between 55 and 55+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 63 and 63+10
          or ss_coupon_amt between 8682 and 8682+1000
          or ss_wholesale_cost between 13 and 13+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 82 and 82+10
          or ss_coupon_amt between 10810 and 10810+1000
          or ss_wholesale_cost between 19 and 19+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 74 and 74+10
          or ss_coupon_amt between 3882 and 3882+1000
          or ss_wholesale_cost between 62 and 62+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 178 and 178+10
          or ss_coupon_amt between 10236 and 10236+1000
          or ss_wholesale_cost between 11 and 11+20)) B6
limit 100;
