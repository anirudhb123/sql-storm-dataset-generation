
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.web_site_sk, ws.web_site_id
),
TopSites AS (
    SELECT 
        web_site_sk, 
        web_site_id, 
        total_sales, 
        order_count 
    FROM RankedSales 
    WHERE sales_rank <= 5
),
CustomerReturns AS (
    SELECT 
        sr_refunded_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    GROUP BY sr_refunded_customer_sk
    HAVING SUM(sr_return_amt_inc_tax) > 100
)
SELECT 
    ts.web_site_id,
    ts.total_sales,
    ts.order_count,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount
FROM TopSites ts
LEFT JOIN CustomerReturns cr ON ts.web_site_sk = cr.sr_refunded_customer_sk
ORDER BY ts.total_sales DESC;

WITH ItemStats AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        AVG(ws.ws_sales_price) AS average_sales_price,
        SUM(ws.ws_ext_sales_price) AS total_sales_value
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
    HAVING total_quantity_sold > 100
)
SELECT 
    item_id,
    total_orders,
    total_quantity_sold,
    average_sales_price,
    total_sales_value,
    CASE 
        WHEN total_sales_value > 5000 THEN 'High Volume'
        WHEN total_sales_value BETWEEN 1000 AND 5000 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS sales_category
FROM ItemStats
WHERE average_sales_price IS NOT NULL
ORDER BY total_sales_value DESC;
