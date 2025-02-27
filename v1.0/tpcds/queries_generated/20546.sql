
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rnk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
),
AggregateStats AS (
    SELECT 
        CASE 
            WHEN SUM(CASE WHEN rnk = 1 THEN ws_sales_price ELSE 0 END) > 0 
            THEN SUM(ws_sales_price) / NULLIF(SUM(CASE WHEN rnk = 1 THEN ws_sales_price ELSE 0 END), 0)
            ELSE 0
        END AS avg_sales_price,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        RankedSales
)
SELECT 
    ca.ca_country,
    ca.ca_state,
    COUNT(distinct c.c_customer_sk) AS customer_count,
    ag.avg_sales_price,
    SUM(CASE 
            WHEN c.c_birth_year IS NULL THEN 0 
            ELSE 1 
        END) AS valid_birth_years,
    COUNT(DISTINCT st.s_store_sk) AS store_count,
    CASE 
        WHEN (ag.total_net_profit + 1) = 0 THEN 'No Profit' 
        ELSE 'Profit Made' 
    END AS profit_status
FROM 
    customer c 
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    store st ON st.s_zip = ca.ca_zip
LEFT JOIN 
    AggregateStats ag ON true
GROUP BY 
    ca.ca_country,
    ca.ca_state,
    ag.avg_sales_price
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > (SELECT COUNT(*) FROM customer) / 100
ORDER BY 
    ca.ca_state, 
    customer_count DESC
LIMIT 10
UNION ALL
SELECT 
    'N/A' AS country,
    'N/A' AS state,
    0 AS customer_count,
    AVG(NULLIF(ws_ext_sales_price, 0)) AS avg_sales_price,
    NULL AS valid_birth_years,
    0 AS store_count,
    'No Profit' AS profit_status
FROM 
    web_sales
WHERE 
    ws_sold_date_sk IS NOT NULL;
