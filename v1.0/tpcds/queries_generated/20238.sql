
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk IS NOT NULL
    GROUP BY 
        ws_bill_customer_sk
), customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_addr_sk,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        COALESCE(ca.ca_country, 'Unknown') AS country
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_marital_status IS NOT NULL AND 
        cd.cd_gender = 'F' 
), sales_summary AS (
    SELECT 
        gi.ws_bill_customer_sk,
        COUNT(DISTINCT gi.ws_order_number) AS total_orders,
        COUNT(gi.ws_item_sk) AS total_items_sold,
        SUM(gi.ws_net_paid_inc_tax) AS total_net_revenue
    FROM 
        web_sales gi
    GROUP BY 
        gi.ws_bill_customer_sk
), complex_query AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_email_address,
        ss.total_orders,
        ss.total_items_sold,
        ss.total_net_revenue,
        rs.total_net_profit
    FROM 
        customer_info ci
    JOIN 
        sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN 
        ranked_sales rs ON ci.c_customer_sk = rs.ws_bill_customer_sk
    WHERE 
        (ss.total_net_revenue IS NULL OR ss.total_net_revenue > 1000)
        AND (rs.profit_rank IS NULL OR rs.profit_rank < 10)
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ci.ca_city,
    SUM(s.ss_net_profit) AS total_profit,
    AVG(CASE WHEN s.ss_sales_price > 100 THEN s.ss_sales_price ELSE NULL END) AS avg_high_sales_price,
    STRING_AGG(DISTINCT s.ws_order_number::text, ', ') AS order_numbers
FROM 
    web_sales s
JOIN 
    customer c ON s.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    complex_query ci ON ci.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    store_returns sr ON s.ws_item_sk = sr.sr_item_sk AND sr.sr_customer_sk = c.c_customer_sk
WHERE 
    ci.total_orders > 0
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ci.ca_city
HAVING 
    COUNT(DISTINCT s.ws_order_number) > 5
ORDER BY 
    total_profit DESC
LIMIT 50 OFFSET (SELECT (COUNT(DISTINCT c.c_customer_sk) / 2) FROM customer c);
