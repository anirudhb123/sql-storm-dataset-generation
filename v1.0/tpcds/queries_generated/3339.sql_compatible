
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
), 
StoreSalesSummary AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_order_number) AS total_orders
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ss.ss_store_sk
)
SELECT 
    ca.ca_state,
    SUM(COALESCE(rs.ws_net_profit, 0)) AS total_web_sales,
    SUM(COALESCE(ss.total_net_profit, 0)) AS total_store_sales,
    COUNT(DISTINCT rs.ws_order_number) AS web_sales_count,
    MAX(rs.ws_net_profit) AS max_web_sale,
    MIN(ss.total_orders) AS min_store_orders
FROM 
    customer_address ca
LEFT JOIN 
    RankedSales rs ON rs.ws_item_sk = ca.ca_address_sk
FULL OUTER JOIN 
    StoreSalesSummary ss ON ss.ss_store_sk = ca.ca_county
WHERE 
    ca.ca_state IN ('CA', 'TX', 'NY')
GROUP BY 
    ca.ca_state
HAVING 
    SUM(COALESCE(rs.ws_net_profit, 0)) > 0 OR SUM(COALESCE(ss.total_net_profit, 0)) > 0
ORDER BY 
    total_web_sales DESC, total_store_sales DESC;
