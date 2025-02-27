
-- end query 35 in stream 0 using template query67.tpl
-- start query 36 in stream 0 using template query28.tpl
select  *
from (select avg(ss_list_price) B1_LP
            ,count(ss_list_price) B1_CNT
            ,count(distinct ss_list_price) B1_CNTD
      from store_sales
      where ss_quantity between 0 and 5
        and (ss_list_price between 38 and 38+10 
             or ss_coupon_amt between 3422 and 3422+1000
             or ss_wholesale_cost between 43 and 43+20)) B1,
     (select avg(ss_list_price) B2_LP
            ,count(ss_list_price) B2_CNT
            ,count(distinct ss_list_price) B2_CNTD
      from store_sales
      where ss_quantity between 6 and 10
        and (ss_list_price between 12 and 12+10
          or ss_coupon_amt between 3437 and 3437+1000
          or ss_wholesale_cost between 58 and 58+20)) B2,
     (select avg(ss_list_price) B3_LP
            ,count(ss_list_price) B3_CNT
            ,count(distinct ss_list_price) B3_CNTD
      from store_sales
      where ss_quantity between 11 and 15
        and (ss_list_price between 164 and 164+10
          or ss_coupon_amt between 15290 and 15290+1000
          or ss_wholesale_cost between 30 and 30+20)) B3,
     (select avg(ss_list_price) B4_LP
            ,count(ss_list_price) B4_CNT
            ,count(distinct ss_list_price) B4_CNTD
      from store_sales
      where ss_quantity between 16 and 20
        and (ss_list_price between 104 and 104+10
          or ss_coupon_amt between 5646 and 5646+1000
          or ss_wholesale_cost between 7 and 7+20)) B4,
     (select avg(ss_list_price) B5_LP
            ,count(ss_list_price) B5_CNT
            ,count(distinct ss_list_price) B5_CNTD
      from store_sales
      where ss_quantity between 21 and 25
        and (ss_list_price between 188 and 188+10
          or ss_coupon_amt between 6531 and 6531+1000
          or ss_wholesale_cost between 25 and 25+20)) B5,
     (select avg(ss_list_price) B6_LP
            ,count(ss_list_price) B6_CNT
            ,count(distinct ss_list_price) B6_CNTD
      from store_sales
      where ss_quantity between 26 and 30
        and (ss_list_price between 114 and 114+10
          or ss_coupon_amt between 3266 and 3266+1000
          or ss_wholesale_cost between 3 and 3+20)) B6
limit 100;
