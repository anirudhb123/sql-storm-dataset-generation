
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk, 
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
      AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
total_sales AS (
    SELECT 
        item.i_item_id,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_revenue,
        SUM(sd.ws_quantity) AS total_quantity
    FROM sales_data sd
    JOIN item ON sd.ws_item_sk = item.i_item_sk
    GROUP BY item.i_item_id
),
customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS customer_revenue
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id
),
avg_revenue AS (
    SELECT 
        cs.c_customer_id, 
        cs.customer_revenue,
        (SELECT AVG(total_revenue) FROM total_sales) AS avg_revenue
    FROM customer_sales cs
)
SELECT 
    DISTINCT ca.ca_city,
    ca.ca_state,
    CASE 
        WHEN ar.customer_revenue IS NULL THEN 'No Revenue'
        WHEN ar.customer_revenue < ar.avg_revenue THEN 'Below Average'
        ELSE 'Above Average'
    END AS revenue_status
FROM customer_address ca
LEFT JOIN avg_revenue ar ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = ar.c_customer_id)
WHERE ca.ca_state IN ('CA', 'NY', 'TX')
ORDER BY ca.ca_city;
