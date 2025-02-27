
WITH RECURSIVE item_path AS (
    SELECT i_item_sk, i_item_id, i_item_desc
    FROM item
    WHERE i_current_price > 100.00
    
    UNION ALL
    
    SELECT i.i_item_sk, i.i_item_id, i.i_item_desc
    FROM item i
    JOIN item_path ip ON i.i_item_sk = ip.i_item_sk
    WHERE i.i_current_price < ip.i_current_price
),
sales_summary AS (
    SELECT 
        ws.ws_web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(distinct ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    GROUP BY ws.ws_web_site_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        cd.cd_gender,
        AVG(ws.ws_sales_price) AS avg_purchase,
        COUNT(*) AS purchase_count
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY c.c_customer_sk, ca.ca_city, cd.cd_gender
),
return_stats AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    GROUP BY sr_item_sk
)
SELECT 
    ci.ca_city,
    ci.cd_gender,
    ss.total_sales,
    ss.total_orders,
    ss.avg_sales_price,
    ci.avg_purchase,
    ci.purchase_count,
    ip.i_item_desc,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount
FROM sales_summary ss
JOIN customer_info ci ON ss.ws_web_site_sk = ci.c_customer_sk
LEFT JOIN item_path ip ON ci.avg_purchase < 50
LEFT JOIN return_stats rs ON ip.i_item_sk = rs.sr_item_sk
WHERE ci.purchase_count > 5
ORDER BY total_sales DESC, ci.ca_city;
