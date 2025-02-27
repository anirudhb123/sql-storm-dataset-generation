
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price * ws_quantity) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        MAX(cd.credit_rating) AS max_credit_rating,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_items_purchased
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
), 
AddressCounts AS (
    SELECT 
        ca.ca_address_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk
)
SELECT 
    a.ca_city,
    COALESCE(ac.customer_count, 0) AS total_customers,
    COUNT(DISTINCT cs.c_customer_sk) AS active_customers,
    SUM(ss.ss_net_profit) AS total_store_profit,
    SUM(ws.total_sales) AS total_web_sales
FROM 
    customer_address a
LEFT JOIN 
    AddressCounts ac ON a.ca_address_sk = ac.ca_address_sk
LEFT JOIN 
    CustomerStats cs ON cs.max_credit_rating IS NOT NULL
LEFT JOIN 
    store_sales ss ON ss.ss_ticket_number IN (SELECT sr_ticket_number FROM store_returns sr WHERE sr.return_quantity > 0)
LEFT JOIN 
    SalesCTE ws ON ws.ws_item_sk IN (SELECT ws_item_sk FROM web_sales)
WHERE 
    (a.ca_state = 'CA' OR a.ca_state IS NULL)
    AND ac.customer_count > 5
GROUP BY 
    a.ca_city, ac.customer_count
HAVING 
    SUM(ss.ss_net_profit) > 10000
ORDER BY 
    total_web_sales DESC;
