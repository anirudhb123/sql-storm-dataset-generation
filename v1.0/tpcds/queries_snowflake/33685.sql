
WITH RECURSIVE sales_summary AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
customer_spending AS (
    SELECT
        c.c_customer_sk,
        SUM(ws_ext_sales_price) AS total_spent
    FROM
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk
),
address_info AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM
        customer_address
)
SELECT 
    cs.c_customer_sk,
    MAX(cs.total_spent) AS max_spent,
    COUNT(DISTINCT ss.total_orders) AS diverse_purchases,
    ai.full_address,
    CASE 
        WHEN MAX(cs.total_spent) IS NULL THEN 'No Purchases'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    customer_spending cs
LEFT JOIN
    sales_summary ss ON cs.c_customer_sk = ss.ws_item_sk
LEFT JOIN
    address_info ai ON ai.ca_address_sk = (
        SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = cs.c_customer_sk 
    )
WHERE
    cs.total_spent > (SELECT AVG(total_spent) FROM customer_spending) 
GROUP BY 
    cs.c_customer_sk, ai.full_address
HAVING 
    COUNT(DISTINCT ss.total_orders) > 1
ORDER BY 
    max_spent DESC;
