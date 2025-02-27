
WITH RECURSIVE SalesHierarchy AS (
    SELECT ws.web_site_sk, ws.web_name, 1 AS level
    FROM web_site ws
    WHERE ws.web_open_date_sk IS NOT NULL
    UNION ALL
    SELECT ws.web_site_sk, ws.web_name, sh.level + 1
    FROM web_site ws
    JOIN SalesHierarchy sh ON sh.web_site_sk = ws.web_site_sk
    WHERE sh.level < 5
),
TotalSales AS (
    SELECT 
        ws.ws_web_site_sk,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_web_site_sk
),
ReturnStats AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns,
        SUM(cr.cr_return_amt) AS total_return_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        COALESCE(ts.total_sales, 0) - COALESCE(rs.total_return_amount, 0) AS net_sales
    FROM item i
    LEFT JOIN TotalSales ts ON i.i_item_sk = ts.ws_web_site_sk
    LEFT JOIN ReturnStats rs ON i.i_item_sk = rs.cr_item_sk
    WHERE i.i_current_price > 20.00
),
SalesSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY c.c_customer_id
)
SELECT 
    s.web_name,
    ti.i_product_name,
    ss.total_net_paid,
    ss.total_orders,
    CASE 
        WHEN ss.total_net_paid IS NULL THEN 'No Sales'
        WHEN ss.total_net_paid > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_type,
    sh.level
FROM SalesHierarchy sh
JOIN TotalSales s ON sh.web_site_sk = s.ws_web_site_sk
JOIN TopItems ti ON s.ws_web_site_sk = ti.i_item_id
LEFT JOIN SalesSummary ss ON ss.total_orders > 0
ORDER BY ss.total_net_paid DESC, sh.level ASC;
