
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
high_value_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        RANK() OVER (PARTITION BY cd.cd_credit_rating ORDER BY SUM(ws_ext_sales_price) DESC) AS rank_by_credit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_marital_status, cd.cd_credit_rating
    HAVING COUNT(ws.ws_order_number) > 10
),
address_with_sales AS (
    SELECT 
        ca.ca_address_id,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_sales_price) AS total_sales
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY ca.ca_address_id
    HAVING SUM(ws.ws_sales_price) IS NOT NULL
)
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    a.ca_address_id,
    COALESCE(a.order_count, 0) AS order_count,
    COALESCE(a.total_sales, 0.00) AS total_sales,
    COALESCE(r.total_sales, 0.00) AS ranked_sales_total,
    hd.hd_buy_potential,
    CASE 
        WHEN cd.cd_marital_status = 'M' THEN 'Married'
        ELSE 'Not Married'
    END AS marital_status,
    CASE 
        WHEN r.sales_rank IS NOT NULL THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS seller_status
FROM high_value_customers hv
JOIN customer c ON hv.c_customer_id = c.c_customer_id
JOIN address_with_sales a ON c.c_current_addr_sk = a.ca_address_id
LEFT JOIN ranked_sales r ON a.ws_item_sk = r.ws_item_sk AND r.sales_rank = 1
LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE 
    (COALESCE(a.order_count, 0) > 1 OR hd.hd_vehicle_count IS NOT NULL)
    AND (r.total_sales > 1000 OR hd.hd_buy_potential LIKE 'High%')
ORDER BY a.total_sales DESC, c.c_last_name, c.c_first_name
LIMIT 100;
