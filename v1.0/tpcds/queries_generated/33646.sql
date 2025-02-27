
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ss_store_sk,
        COUNT(ss_ticket_number) AS total_sales,
        SUM(ss_net_profit) AS total_profit
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_store_sk
    UNION ALL
    SELECT 
        s_store_sk,
        COUNT(ss_ticket_number) + cte.total_sales,
        SUM(ss_net_profit) + cte.total_profit
    FROM 
        store_sales ss
    JOIN 
        SalesCTE cte ON ss.ss_store_sk = cte.ss_store_sk
    WHERE 
        ss_sold_date_sk < (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
)
SELECT 
    ca_state,
    SUM(total_sales) AS annual_sales,
    AVG(total_profit) AS average_profit,
    MAX(total_profit) AS max_profit,
    COUNT(DISTINCT ss_item_sk) AS unique_items_sold
FROM 
    SalesCTE cte
JOIN 
    customer c ON c.c_customer_sk IN (SELECT DISTINCT c_customer_sk FROM store_sales)
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    store s ON s.s_store_sk = cte.ss_store_sk
WHERE 
    ca.ca_state IS NOT NULL AND ca.ca_state != ''
GROUP BY 
    ca_state
ORDER BY 
    annual_sales DESC
LIMIT 10;
