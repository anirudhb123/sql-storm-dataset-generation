
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022) 
        AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
),
aggregated_data AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(r.ws_net_profit) AS total_profit,
        CASE 
            WHEN COUNT(DISTINCT c.c_customer_sk) = 0 THEN NULL 
            ELSE SUM(r.ws_net_profit) / COUNT(DISTINCT c.c_customer_sk)
        END AS avg_profit_per_customer
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        ranked_sales r ON r.web_site_sk = c.c_customer_sk
    GROUP BY 
        ca.ca_state
)
SELECT 
    ad.ca_state,
    ad.customer_count,
    ad.total_profit,
    ad.avg_profit_per_customer,
    CASE 
        WHEN ad.avg_profit_per_customer IS NULL THEN 'No Data'
        ELSE CASE 
            WHEN ad.avg_profit_per_customer < 100 THEN 'Low Profit'
            WHEN ad.avg_profit_per_customer BETWEEN 100 AND 500 THEN 'Medium Profit'
            ELSE 'High Profit'
        END
    END AS profit_category
FROM 
    aggregated_data ad
WHERE 
    ad.total_profit IS NOT NULL
ORDER BY 
    ad.total_profit DESC
LIMIT 10;
