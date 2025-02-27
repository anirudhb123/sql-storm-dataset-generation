
WITH RECURSIVE SalesData AS (
    SELECT 
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_item_sk ORDER BY ss.ss_sold_date_sk DESC) AS rn
    FROM 
        store_sales ss
    WHERE 
        ss.ss_net_profit > 0

    UNION ALL

    SELECT 
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_item_sk ORDER BY ss.ss_sold_date_sk DESC) AS rn
    FROM 
        store_sales ss
    INNER JOIN SalesData sd ON 
        ss.ss_item_sk = sd.ss_item_sk AND 
        sd.ss_quantity < ss.ss_quantity
)

SELECT 
    ca.ca_city,
    SUM(sd.ss_quantity) AS total_quantity,
    AVG(sd.ss_net_paid) AS average_net_paid,
    COUNT(DISTINCT sd.ss_ticket_number) AS unique_sales_count,
    MAX(sd.ss_net_profit) AS highest_net_profit,
    CASE 
        WHEN SUM(sd.ss_net_paid) > 5000 THEN 'High Sales'
        WHEN SUM(sd.ss_net_paid) BETWEEN 2000 AND 5000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    SalesData sd
JOIN 
    customer c ON c.c_customer_sk = sd.ss_customer_sk
JOIN 
    customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT sd.ss_ticket_number) > 10
ORDER BY 
    total_quantity DESC
LIMIT 10;
