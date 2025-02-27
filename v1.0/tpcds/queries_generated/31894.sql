
WITH RECURSIVE ItemHierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, i_current_price, i_rec_start_date, i_rec_end_date, i_brand_id
    FROM item
    WHERE i_rec_start_date <= CURRENT_DATE AND (i_rec_end_date IS NULL OR i_rec_end_date > CURRENT_DATE)
    UNION ALL
    SELECT i.i_item_sk, i.i_item_id, i.i_item_desc, i.i_current_price, i.i_rec_start_date, i.i_rec_end_date, i.i_brand_id
    FROM item i
    JOIN ItemHierarchy ih ON i.i_brand_id = ih.i_brand_id
    WHERE i.i_rec_start_date <= CURRENT_DATE AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE)
),
CustomerReturns AS (
    SELECT sr_customer_sk, SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM store_returns
    GROUP BY sr_customer_sk
),
WebReturns AS (
    SELECT wr_returning_customer_sk, SUM(wr_return_amt_inc_tax) AS total_web_return_amt
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
TotalReturns AS (
    SELECT COALESCE(cr.sr_customer_sk, wr.wr_returning_customer_sk) AS customer_sk,
           COALESCE(cr.total_return_amt, 0) + COALESCE(wr.total_web_return_amt, 0) AS total_return
    FROM CustomerReturns cr
    FULL OUTER JOIN WebReturns wr ON cr.sr_customer_sk = wr.wr_returning_customer_sk
),
SalesSummary AS (
    SELECT ws_bill_customer_sk AS customer_sk,
           SUM(ws_ext_sales_price) AS total_web_sales,
           COUNT(DISTINCT ws_order_number) AS total_web_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT cs.c_customer_id,
       cs.c_first_name,
       cs.c_last_name,
       COALESCE(ts.total_return, 0) AS total_return,
       ss.total_web_sales,
       ss.total_web_orders,
       ROW_NUMBER() OVER (PARTITION BY cs.c_customer_id ORDER BY total_return DESC) AS return_rank,
       CASE WHEN ss.total_web_sales > 500 THEN 'Gold' 
            WHEN ss.total_web_sales BETWEEN 100 AND 500 THEN 'Silver'
            ELSE 'Bronze' END AS customer_tier
FROM customer cs
LEFT JOIN TotalReturns ts ON cs.c_customer_sk = ts.customer_sk
LEFT JOIN SalesSummary ss ON cs.c_customer_sk = ss.customer_sk
WHERE (ts.total_return > 0 OR ss.total_web_sales > 0) 
  AND cs.c_birth_year IS NOT NULL
ORDER BY total_return DESC, total_web_sales DESC
LIMIT 100;
