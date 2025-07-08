
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopItemSales AS (
    SELECT
        ws_item_sk,
        total_profit,
        total_sales
    FROM 
        SalesCTE
    WHERE 
        rn <= 10
),
CustomerProfits AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS customer_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
AddressInfo AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer_address ca
    WHERE 
        ca.ca_country = 'USA'
),
FinalResults AS (
    SELECT 
        tp.ws_item_sk,
        tp.total_profit,
        tp.total_sales,
        COALESCE(cp.customer_profit, 0) AS customer_profit,
        ai.ca_city,
        ai.ca_state
    FROM 
        TopItemSales tp
    LEFT JOIN 
        CustomerProfits cp ON cp.c_customer_sk = (
            SELECT MAX(c.c_customer_sk) 
            FROM customer c 
            JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
            WHERE ws.ws_item_sk = tp.ws_item_sk
        )
    LEFT JOIN 
        AddressInfo ai ON ai.ca_address_sk = (
            SELECT c.c_current_addr_sk 
            FROM customer c 
            WHERE c.c_customer_sk = cp.c_customer_sk
        )
)
SELECT 
    ws_item_sk,
    total_profit,
    total_sales,
    customer_profit,
    ca_city,
    ca_state
FROM 
    FinalResults
WHERE 
    total_profit >= (SELECT AVG(total_profit) FROM TopItemSales)
ORDER BY 
    total_profit DESC;
