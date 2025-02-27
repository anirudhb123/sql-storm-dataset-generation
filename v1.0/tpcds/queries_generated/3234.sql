
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        AVG(ws.ws_net_profit) AS average_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY 
        ws.ws_item_sk
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws.ws_ext_sales_price) > 1000
),
high_value_customers AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        RANK() OVER (ORDER BY tc.total_spent DESC) AS customer_rank
    FROM 
        top_customers tc
    WHERE 
        EXISTS (SELECT 1 FROM customer_demographics cd WHERE cd.cd_demo_sk = c.c_current_cdemo_sk AND cd.cd_credit_rating = 'High')
)
SELECT 
    s.item_id,
    ss.total_sales_quantity,
    ss.total_sales_amount,
    ss.average_net_profit,
    ns.rank AS sales_rank,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_spent
FROM 
    sales_summary ss
JOIN 
    item i ON ss.ws_item_sk = i.i_item_sk
LEFT JOIN 
    high_value_customers hvc ON hvc.c_customer_sk = ss.ws_item_sk 
JOIN 
    (SELECT ws.ws_item_sk, RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) as rank
     FROM web_sales ws GROUP BY ws.ws_item_sk) AS ns ON ss.ws_item_sk = ns.ws_item_sk
WHERE 
    ss.sales_rank <= 10
ORDER BY 
    ss.total_sales_amount DESC;
