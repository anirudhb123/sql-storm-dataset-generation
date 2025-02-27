
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk, 
        COUNT(*) AS sales_count,
        SUM(ws_net_profit) AS total_profit,
        SUM(ws_net_paid_inc_tax) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
), 
AddressInfo AS (
    SELECT 
        ca_address_sk, 
        CONCAT_WS(', ', ca_street_number, ca_street_name, ca_city, ca_state, ca_zip) AS full_address
    FROM 
        customer_address
), 
CustomerStats AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        ca.full_address, 
        cd_credit_rating,
        cd_gender,
        rank() OVER (PARTITION BY ca.ca_state ORDER BY COUNT(DISTINCT ws_order_number) DESC) AS customer_rank
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        AddressInfo ca ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c_customer_sk, c_first_name, c_last_name, ca.full_address, cd_credit_rating, cd_gender
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.full_address,
    cs.cd_credit_rating,
    cs.cd_gender,
    COALESCE(s.sales_count, 0) AS sales_count,
    COALESCE(s.total_profit, 0) AS total_profit,
    COALESCE(s.total_revenue, 0) AS total_revenue
FROM 
    CustomerStats cs
LEFT JOIN 
    SalesCTE s ON s.ws_item_sk = cs.c_customer_sk
WHERE 
    cs.customer_rank <= 10
ORDER BY 
    cs.full_address, total_profit DESC;

