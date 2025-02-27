
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank,
        COALESCE(NULLIF(ws.ws_sales_price, 0), NULL) AS adjusted_price
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 1 AND 365
),
highest_sales AS (
    SELECT 
        r.web_site_sk,
        r.ws_order_number,
        r.ws_item_sk,
        r.ws_sales_price
    FROM ranked_sales r
    WHERE r.sales_rank = 1
),
total_returns AS (
    SELECT 
        cr.returned_date_sk,
        cr.returning_customer_sk,
        SUM(cr.return_quantity) AS total_returned
    FROM catalog_returns cr
    GROUP BY cr.returned_date_sk, cr.returning_customer_sk
),
item_inventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
customer_status AS (
    SELECT 
        c.c_customer_sk, 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cr.total_returned) AS return_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN total_returns cr ON c.c_customer_sk = cr.returning_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ws.web_site_sk,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    SUM(ws.ws_sales_price) AS total_revenue,
    AVG(ws.ws_sales_price) AS average_sales_price,
    CASE 
        WHEN SUM(c.return_count) IS NULL THEN 'No Returns'
        ELSE 'Returns Exist'
    END AS return_status
FROM highest_sales ws
JOIN customer_status c ON c.return_count > 0
LEFT OUTER JOIN item_inventory ii ON ii.inv_item_sk = ws.ws_item_sk
WHERE ws.ws_sales_price > (
    SELECT AVG(ws_sales_price) FROM highest_sales
) * 0.9
GROUP BY ws.web_site_sk
HAVING COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY total_revenue DESC
FETCH FIRST 10 ROWS ONLY;
