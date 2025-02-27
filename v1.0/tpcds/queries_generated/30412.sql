
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        ws_quantity, 
        ws_sales_price, 
        ws_net_profit, 
        1 AS level
    FROM web_sales
    WHERE ws_item_sk IS NOT NULL
    
    UNION ALL
    
    SELECT 
        cs_sold_date_sk, 
        cs_item_sk, 
        cs_quantity, 
        cs_sales_price, 
        cs_net_profit, 
        level + 1
    FROM catalog_sales
    WHERE cs_item_sk IS NOT NULL AND level < 5
),
top_sales AS (
    SELECT 
        item.i_item_id, 
        SUM(sd.ws_quantity) AS total_quantity,
        AVG(sd.ws_sales_price) AS avg_sales_price,
        SUM(sd.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (ORDER BY SUM(sd.ws_net_profit) DESC) AS sales_rank
    FROM sales_data sd
    JOIN item i ON sd.ws_item_sk = i.i_item_sk
    GROUP BY item.i_item_id
),
@latest_dates AS (
    SELECT DISTINCT d.d_date
    FROM date_dim d
    WHERE d.d_date = (SELECT MAX(d_date) FROM date_dim)
),
customer_sales AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
)
SELECT 
    cs.c_customer_id, 
    cs.order_count,
    cs.total_spent,
    ts.total_quantity,
    ts.avg_sales_price,
    ts.total_net_profit,
    @latest_dates.d_date,
    COALESCE(ca.ca_city, 'Unknown') AS location
FROM customer_sales cs
LEFT JOIN top_sales ts ON cs.order_count > 10
LEFT JOIN customer_address ca ON cs.c_customer_id = ca.ca_address_id
WHERE cs.total_spent > 1000 OR ts.sales_rank <= 5
ORDER BY cs.total_spent DESC
LIMIT 50;
