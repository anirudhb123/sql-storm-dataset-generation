
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451000 AND 2451090
    GROUP BY ws_sold_date_sk, ws_item_sk
),
top_items AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        i.i_item_desc,
        i.i_brand
    FROM sales_summary ss
    JOIN item i ON ss.ws_item_sk = i.i_item_sk
    WHERE sales_rank <= 10
),
customer_metrics AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent
    FROM web_sales ws
    JOIN customer c ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT cm.c_customer_sk) AS unique_customers,
    AVG(cm.total_spent) AS average_spending,
    SUM(ti.total_quantity) AS total_quantity_sold,
    SUM(ti.total_sales) AS total_sales_voltage,
    CASE 
        WHEN COUNT(DISTINCT cm.c_customer_sk) = 0 THEN NULL 
        ELSE COUNT(DISTINCT cm.c_customer_sk) / AVG(cm.total_spent)
    END AS customer_spending_ratio
FROM customer_address ca
JOIN customer_metrics cm ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = cm.c_customer_sk)
LEFT JOIN top_items ti ON 1 = 1
WHERE ca.ca_state = 'NY'
GROUP BY ca.ca_city
ORDER BY total_sales_voltage DESC;
