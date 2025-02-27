
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_net_paid,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_quantity DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT s.ss_ticket_number) AS total_sales,
        SUM(s.ss_net_profit) AS total_net_profit,
        AVG(d.d_year) AS avg_year 
    FROM 
        customer c
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    JOIN 
        date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        cs.total_sales,
        cs.total_net_profit
    FROM 
        customer_stats cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_sales > 10 AND 
        cs.total_net_profit > (SELECT AVG(total_net_profit) FROM customer_stats)
    ORDER BY 
        cs.total_net_profit DESC
)
SELECT 
    tc.c_customer_sk,
    tc.total_sales,
    tc.total_net_profit,
    JSON_ARRAYAGG(
        JSON_OBJECT(
            'item_sk', sd.ws_item_sk,
            'order_number', sd.ws_order_number,
            'quantity', sd.ws_quantity,
            'sales_price', sd.ws_sales_price,
            'net_paid', sd.ws_net_paid
        )
    ) AS items_details
FROM 
    top_customers tc
LEFT JOIN 
    sales_data sd ON tc.c_customer_sk = sd.ws_item_sk
GROUP BY 
    tc.c_customer_sk, tc.total_sales, tc.total_net_profit
HAVING 
    COUNT(sd.ws_item_sk) > 2
ORDER BY 
    tc.total_net_profit DESC;
