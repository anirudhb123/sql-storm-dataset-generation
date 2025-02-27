
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
    HAVING 
        SUM(ws_net_profit) > 1000
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        COUNT(cs_order_number) AS total_orders,
        SUM(cs_net_profit) AS total_profit
    FROM 
        catalog_sales
    WHERE 
        cs_promo_sk IS NOT NULL
    GROUP BY 
        cs_sold_date_sk
    HAVING 
        SUM(cs_net_profit) > 1000
),
address_counts AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca_state
),
most_profitable_days AS (
    SELECT 
        d.d_date,
        s.total_orders,
        s.total_profit,
        ROW_NUMBER() OVER (ORDER BY s.total_profit DESC) AS rank
    FROM 
        date_dim d
    JOIN 
        sales_summary s ON d.d_date_sk = s.ws_sold_date_sk
    WHERE 
        d.d_year = 2023
)
SELECT 
    md.d_date,
    md.total_orders,
    md.total_profit,
    ac.ca_state,
    ac.customer_count,
    COALESCE((SELECT COUNT(*) FROM promotion p WHERE p.p_start_date_sk <= md.ws_sold_date_sk AND p.p_end_date_sk >= md.ws_sold_date_sk), 0) AS active_promotions
FROM 
    most_profitable_days md
JOIN 
    address_counts ac ON ac.customer_count > 50
WHERE 
    md.rank <= 10
ORDER BY 
    md.total_profit DESC;
