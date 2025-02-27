
WITH AddressInfo AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip,
        ca.ca_street_name,
        ca.ca_street_number,
        ca.ca_street_type
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_bill_customer_sk,
        ws.ws_ship_customer_sk
    FROM 
        web_sales ws
    UNION ALL
    SELECT 
        cs.cs_order_number,
        cs.cs_sales_price,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk
    FROM 
        catalog_sales cs
    UNION ALL
    SELECT 
        ss.ss_ticket_number,
        ss.ss_sales_price,
        ss.ss_quantity,
        ss.ss_net_profit,
        ss.ss_customer_sk,
        ss.ss_customer_sk
    FROM 
        store_sales ss
),
CustomerSales AS (
    SELECT 
        ai.customer_name,
        ai.ca_city,
        ai.ca_state,
        ai.ca_country,
        ai.ca_zip,
        SUM(si.ws_sales_price) AS total_sales,
        SUM(si.ws_net_profit) AS total_profit
    FROM 
        AddressInfo ai
    JOIN 
        SalesInfo si ON ai.customer_name LIKE CONCAT('%', CAST(si.ws_bill_customer_sk AS CHAR), '%') OR ai.customer_name LIKE CONCAT('%', CAST(si.ws_ship_customer_sk AS CHAR), '%')
    GROUP BY 
        ai.customer_name, ai.ca_city, ai.ca_state, ai.ca_country, ai.ca_zip
)
SELECT 
    customer_name,
    ca_city,
    ca_state,
    ca_country,
    ca_zip,
    total_sales,
    total_profit,
    ROUND(total_profit / NULLIF(total_sales, 0), 2) AS profit_margin
FROM 
    CustomerSales
ORDER BY 
    profit_margin DESC
LIMIT 10;
