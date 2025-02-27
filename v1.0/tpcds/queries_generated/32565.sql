
WITH RECURSIVE SalesCTE AS (
    SELECT ws_item_sk, SUM(ws_net_paid) AS total_net_paid
    FROM web_sales
    GROUP BY ws_item_sk
    UNION ALL
    SELECT cs_item_sk, SUM(cs_net_paid) AS total_net_paid
    FROM catalog_sales
    WHERE cs_item_sk IN (SELECT ws_item_sk FROM SalesCTE)
    GROUP BY cs_item_sk
),
CustomerReturns AS (
    SELECT sr_customer_sk, SUM(sr_return_quantity) AS total_returned_quantity
    FROM store_returns
    GROUP BY sr_customer_sk
),
SalesSummary AS (
    SELECT c.c_customer_id,
           CREATETIME(w.ws_sold_date_sk) AS sale_date,
           SUM(ws_sales_price) AS total_sales,
           SUM(COALESCE(sr_returned_quantity, 0)) AS total_returns,
           COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales ws
    LEFT JOIN CustomerReturns cr ON cr.sr_customer_sk = ws.ws_ship_customer_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
      AND ws_sold_date_sk <= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY c.c_customer_id, ws.ws_sold_date_sk
)
SELECT cs.customer_id,
       cs.sale_date,
       cs.total_sales,
       cs.total_returns,
       (cs.total_sales - cs.total_returns) AS net_sales,
       RANK() OVER (PARTITION BY cs.sale_date ORDER BY net_sales DESC) AS sales_rank
FROM SalesSummary cs
WHERE cs.total_sales IS NOT NULL
ORDER BY cs.sale_date, net_sales DESC;
