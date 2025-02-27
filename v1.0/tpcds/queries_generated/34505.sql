
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        (ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        1 AS level
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 1 AND 10

    UNION ALL

    SELECT 
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        (cs.cs_sales_price * cs.cs_quantity) AS total_sales,
        level + 1
    FROM catalog_sales cs
    JOIN sales_data sd ON cs.cs_order_number = sd.ws_order_number
    WHERE sd.level < 3 
      AND cs.cs_sold_date_sk BETWEEN 1 AND 10
)

SELECT 
    ca.ca_city,
    SUM(sd.total_sales) AS total_sales,
    COUNT(DISTINCT sd.ws_order_number) AS unique_orders,
    AVG(sd.ws_sales_price) AS avg_sales_price,
    MAX(sd.ws_quantity) AS max_quantity_sold
FROM sales_data sd
JOIN customer c ON sd.ws_order_number = c.c_customer_id
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY ca.ca_city
ORDER BY total_sales DESC
LIMIT 10;

WITH monthly_sales AS (
    SELECT 
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS monthly_total
    FROM date_dim d 
    LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_month_seq
),

sales_with_ranks AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY monthly_total DESC) AS sales_rank
    FROM monthly_sales
)

SELECT 
    *
FROM sales_with_ranks
WHERE sales_rank <= 5
ORDER BY d_month_seq;
