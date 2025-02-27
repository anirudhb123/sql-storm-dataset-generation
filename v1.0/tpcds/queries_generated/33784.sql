
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ss_item_sk,
        ss_ticket_number,
        ss_quantity,
        ss_ext_sales_price,
        ss_net_profit,
        1 AS Sales_Level
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)

    UNION ALL

    SELECT 
        ss.item_sk,
        ss.ticket_number,
        ss.quantity,
        ss.ext_sales_price,
        ss.net_profit,
        cte.Sales_Level + 1
    FROM 
        store_sales ss
    JOIN 
        SalesCTE cte ON ss.ss_item_sk = cte.ss_item_sk AND ss.ss_ticket_number < cte.ss_ticket_number
)
SELECT 
    ca.city, 
    COUNT(DISTINCT c.c_customer_sk) AS num_customers,
    SUM(ss.base_sales) AS total_sales,
    AVG(ss.ext_sales_price) AS avg_sales_price,
    MAX(ss.net_profit) AS max_profit
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    (
        SELECT 
            ss_item_sk,
            ss_ticket_number,
            SUM(ss_ext_sales_price) AS base_sales,
            SUM(ss_net_profit) AS net_profit
        FROM 
            store_sales
        GROUP BY 
            ss_item_sk, ss_ticket_number
    ) ss ON ss.ss_item_sk = c.c_customer_sk
LEFT JOIN 
    (
        SELECT 
            ss_item_sk, 
            SUM(ss_quantity) AS total_quantity,
            AVG(ss_ext_sales_price) AS avg_price
        FROM 
            store_sales
        GROUP BY 
            ss_item_sk
        HAVING 
            SUM(ss_quantity) > 10
    ) sr ON sr.ss_item_sk = ss.ss_item_sk
WHERE 
    c.c_birth_year IS NOT NULL 
    AND ca.ca_state = 'CA'
GROUP BY 
    ca.city
HAVING 
    SUM(ss.base_sales) > 10000
ORDER BY 
    num_customers DESC
LIMIT 5;
