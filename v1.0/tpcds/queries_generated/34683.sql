
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           1 AS level
    FROM customer c
    WHERE c.c_preferred_cust_flag = 'Y'
    
    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON ch.c_customer_sk = c.c_current_cdemo_sk
),
SalesData AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_net_paid) AS total_revenue,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_current_cdemo_sk IS NOT NULL
    GROUP BY ws.ws_item_sk
),
FilteredReturns AS (
    SELECT sr_item_sk,
           SUM(sr_return_quantity) AS total_returns,
           SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM (
        SELECT cr.cr_item_sk AS sr_item_sk, cr.cr_return_quantity, cr.cr_return_amt_inc_tax
        FROM catalog_returns cr
        UNION ALL
        SELECT wr.wr_item_sk, wr.wr_return_quantity, wr.wr_return_amt_inc_tax
        FROM web_returns wr
    ) AS combined_returns
    GROUP BY sr_item_sk
)
SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, 
       sd.total_quantity, sd.total_revenue, sd.order_count,
       COALESCE(fr.total_returns, 0) AS total_returns,
       COALESCE(fr.total_return_value, 0.00) AS total_return_value,
       CASE 
           WHEN fr.total_return_value IS NOT NULL AND fr.total_return_value > 0 
           THEN (sd.total_revenue - fr.total_return_value) / NULLIF(sd.total_revenue, 0)
           ELSE NULL 
       END AS adjusted_revenue_percentage,
       ROW_NUMBER() OVER (PARTITION BY ch.c_current_cdemo_sk ORDER BY sd.total_revenue DESC) AS revenue_rank
FROM CustomerHierarchy ch
LEFT JOIN SalesData sd ON ch.c_customer_sk = sd.ws_item_sk
LEFT JOIN FilteredReturns fr ON sd.ws_item_sk = fr.sr_item_sk
WHERE ch.level = 1
ORDER BY adjusted_revenue_percentage DESC, ch.c_last_name;
