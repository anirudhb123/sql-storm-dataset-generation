
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2459506 AND 2459516 -- Example date range
    GROUP BY 
        c.c_customer_id
),
Filtered_Sales AS (
    SELECT 
        *,
        CASE 
            WHEN total_net_profit IS NULL THEN 'No Sales'
            WHEN total_net_profit > 1000 THEN 'High Value Customer'
            ELSE 'Regular Customer'
        END AS customer_segment
    FROM 
        Sales_CTE
)
SELECT 
    f.c_customer_id,
    f.total_net_profit,
    f.total_orders,
    f.customer_segment,
    d.d_year,
    d.d_month_seq,
    d.d_day_name
FROM 
    Filtered_Sales f
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws.ws_sold_date_sk)
                                  FROM web_sales ws 
                                  WHERE ws.ws_ship_customer_sk = f.c_customer_id
                                  AND ws.ws_sold_date_sk BETWEEN 2459506 AND 2459516)
WHERE 
    f.rank <= 10
ORDER BY 
    f.total_net_profit DESC
UNION ALL
SELECT 
    'TOTAL' AS c_customer_id,
    SUM(total_net_profit) AS total_net_profit,
    NULL AS total_orders,
    NULL AS customer_segment,
    NULL AS d_year,
    NULL AS d_month_seq,
    NULL AS d_day_name
FROM 
    Filtered_Sales
WHERE 
    total_net_profit IS NOT NULL
HAVING 
    SUM(total_net_profit) > 5000
ORDER BY 
    total_net_profit DESC;
