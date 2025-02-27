
WITH RankedSales AS (
    SELECT 
        ws.bill_customer_sk,
        ws.ship_customer_sk,
        ws.sku_item_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        ws.bill_customer_sk, ws.ship_customer_sk, ws.sku_item_sk
),
HighSpendingCustomers AS (
    SELECT 
        DISTINCT bill_customer_sk
    FROM 
        RankedSales 
    WHERE 
        sales_rank = 1
),
SalesDetails AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        c.c_first_name,
        c.c_last_name,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ci ON c.c_current_addr_sk = ci.ca_address_sk
    WHERE 
        ws.bill_customer_sk IN (SELECT * FROM HighSpendingCustomers)
)
SELECT 
    s.ws_order_number,
    s.ws_item_sk,
    s.ws_quantity,
    s.ws_net_profit,
    s.ws_ext_sales_price,
    s.c_first_name,
    s.c_last_name,
    s.ca_city,
    s.ca_state,
    s.ca_country,
    COALESCE(s.ws_ext_sales_price / NULLIF(s.ws_quantity, 0), 0) AS avg_price_per_unit,
    CASE 
        WHEN s.ws_net_profit > 1000 THEN 'High Profit'
        WHEN s.ws_net_profit BETWEEN 500 AND 1000 THEN 'Moderate Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    SalesDetails s
WHERE 
    s.ws_ext_sales_price >= (SELECT AVG(ws_ext_sales_price) FROM web_sales)
ORDER BY 
    s.ws_net_profit DESC
LIMIT 100;
