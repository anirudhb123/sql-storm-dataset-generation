
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_sold_date_sk, 
        ws_quantity, 
        ws_net_profit, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_net_profit > COALESCE((SELECT AVG(ws_net_profit) FROM web_sales), 0)
),
CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT o.ss_ticket_number) AS total_sales,
        MAX(o.ss_net_profit) AS highest_sale
    FROM 
        customer c
    LEFT JOIN 
        store_sales o ON c.c_customer_sk = o.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
InventoryCheck AS (
    SELECT 
        i.inv_item_sk,
        SUM(i.inv_quantity_on_hand) AS total_on_hand
    FROM 
        inventory i
    GROUP BY 
        i.inv_item_sk
    HAVING 
        SUM(i.inv_quantity_on_hand) < 10
),
EmailSelector AS (
    SELECT 
        c.c_email_address, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM 
        customer c
    WHERE 
        c.c_birth_month = EXTRACT(MONTH FROM DATE '2002-10-01') 
        AND c.c_birth_day = EXTRACT(DAY FROM DATE '2002-10-01')
        AND c.c_email_address IS NOT NULL
)
SELECT 
    es.full_name,
    es.c_email_address,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.highest_sale, 0) AS highest_sale,
    COALESCE(i.total_on_hand, 0) AS inventory,
    r.ws_item_sk, 
    r.ws_quantity, 
    r.ws_net_profit
FROM 
    EmailSelector es
LEFT JOIN 
    CustomerSummary s ON s.c_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_email_address = es.c_email_address)
LEFT JOIN 
    InventoryCheck i ON i.inv_item_sk IN (SELECT r.ws_item_sk FROM RankedSales r WHERE r.rank = 1)
JOIN 
    RankedSales r ON r.ws_item_sk = i.inv_item_sk
WHERE 
    es.c_email_address LIKE '%@example.com' 
    AND (COALESCE(s.total_sales, 0) > 0 OR s.highest_sale IS NOT NULL)
ORDER BY 
    r.ws_net_profit DESC, 
    s.total_sales DESC
LIMIT 50;
