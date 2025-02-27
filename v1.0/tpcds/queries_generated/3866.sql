
WITH SalesData AS (
    SELECT 
        ws.order_number AS web_order_number,
        ws.quantity AS web_quantity,
        ws.net_profit AS web_net_profit,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY ws.sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ws.sold_date_sk = (SELECT MAX(sold_date_sk) FROM web_sales)
),
StoreSalesData AS (
    SELECT 
        ss.ticket_number AS store_ticket_number,
        ss.quantity AS store_quantity,
        ss.net_profit AS store_net_profit,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY ss.sold_date_sk DESC) AS rn
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ss.sold_date_sk = (SELECT MAX(sold_date_sk) FROM store_sales)
),
TotalSales AS (
    SELECT 
        coalesce(sd.c_customer_id, sd2.c_customer_id) AS customer_id,
        coalesce(sd.web_order_number, 'N/A') AS web_order,
        coalesce(sd.store_ticket_number, 'N/A') AS store_order,
        coalesce(sd.web_quantity, 0) AS total_web_quantity,
        coalesce(sd2.store_quantity, 0) AS total_store_quantity,
        coalesce(sd.web_net_profit, 0) + coalesce(sd2.store_net_profit, 0) AS total_net_profit,
        COALESCE(sd.ca_city, sd2.ca_city) AS city,
        COALESCE(sd.ca_state, sd2.ca_state) AS state
    FROM 
        SalesData sd
    FULL OUTER JOIN 
        StoreSalesData sd2 ON sd.c_customer_id = sd2.c_customer_id
)
SELECT 
    customer_id,
    web_order,
    store_order,
    total_web_quantity,
    total_store_quantity,
    total_net_profit,
    city,
    state
FROM 
    TotalSales
WHERE 
    total_net_profit > 0
    AND (city IS NOT NULL OR state IS NOT NULL)
ORDER BY 
    total_net_profit DESC
LIMIT 100;
