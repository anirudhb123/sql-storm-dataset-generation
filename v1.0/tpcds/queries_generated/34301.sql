
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS ranking
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy = 1)
    GROUP BY ws_item_sk
), 
CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_return_quantity
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
), 
TopSales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        c.c_first_name || ' ' || c.c_last_name AS customer_name,
        s.s_store_name,
        sc.total_quantity,
        sc.total_net_paid
    FROM SalesCTE sc
    JOIN item ON sc.ws_item_sk = item.i_item_sk
    JOIN customer c ON c.c_customer_sk = sc.ws_customer_sk
    JOIN store s ON sc.ws_store_sk = s.s_store_sk
    WHERE sc.ranking <= 10
    ORDER BY sc.total_net_paid DESC
), 
ReturnAnalysis AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
        MAX(ds.d_date) AS last_return_date
    FROM customer c
    LEFT JOIN CustomerReturns cr ON cr.cr_returning_customer_sk = c.c_customer_sk
    LEFT JOIN date_dim ds ON cr.total_return_quantity > 0
    GROUP BY c.c_customer_sk
)
SELECT 
    ts.item_id,
    ts.item_desc,
    ts.customer_name,
    ts.store_name,
    (ts.total_net_paid - COALESCE(ra.total_return_quantity, 0)) AS net_after_returns,
    ra.last_return_date
FROM TopSales ts
LEFT JOIN ReturnAnalysis ra ON ts.customer_name = ra.customer_name
WHERE ts.total_net_paid > 100
ORDER BY net_after_returns DESC;
