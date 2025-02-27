
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           0 AS level
    FROM customer c
    WHERE c.c_customer_sk IS NOT NULL
    
    UNION ALL
    
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
SalesSummary AS (
    SELECT
        CASE
            WHEN ws.ws_sales_price < 20 THEN 'Low'
            WHEN ws.ws_sales_price BETWEEN 20 AND 50 THEN 'Medium'
            ELSE 'High'
        END AS price_band,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY CASE
                                      WHEN ws.ws_sales_price < 20 THEN 'Low'
                                      WHEN ws.ws_sales_price BETWEEN 20 AND 50 THEN 'Medium'
                                      ELSE 'High'
                                  END 
                                  ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY price_band
),
RecentReturns AS (
    SELECT sr_item_sk,
           SUM(sr_return_quantity) AS total_returns,
           AVG(sr_return_amt) AS avg_return_amt
    FROM store_returns
    GROUP BY sr_item_sk
),
NullCheck AS (
    SELECT da.d_date,
           SUM(COALESCE(ws.ws_net_paid, 0)) AS total_paid,
           COUNT(ws.ws_order_number) AS order_count,
           COUNT(DISTINCT CASE WHEN ws.ws_net_paid IS NULL THEN ws.ws_order_number END) AS null_orders
    FROM date_dim da
    LEFT JOIN web_sales ws ON da.d_date_sk = ws.ws_sold_date_sk
    WHERE da.d_date >= '2022-01-01'
    GROUP BY da.d_date
),
FinalReport AS (
    SELECT ch.c_first_name,
           ch.c_last_name,
           s.price_band,
           s.total_sales,
           s.total_orders,
           r.total_returns,
           r.avg_return_amt,
           n.total_paid,
           n.order_count,
           n.null_orders
    FROM CustomerHierarchy ch
    LEFT JOIN SalesSummary s ON s.price_band = CASE
                                                  WHEN ch.c_customer_sk < 100 THEN 'Low'
                                                  WHEN ch.c_customer_sk < 200 THEN 'Medium'
                                                  ELSE 'High'
                                              END
    LEFT JOIN RecentReturns r ON r.sr_item_sk = ch.c_customer_sk
    LEFT JOIN NullCheck n ON n.d_date = (SELECT MAX(d_date) FROM date_dim)
)
SELECT *
FROM FinalReport
WHERE total_sales > 1000
  AND avg_return_amt IS NOT NULL
ORDER BY total_sales DESC, c_first_name;
