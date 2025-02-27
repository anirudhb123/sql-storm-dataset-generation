
WITH AddressCTE AS (
    SELECT 
        ca_address_sk,
        ca_city,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_state
    FROM 
        customer_address
    WHERE 
        ca_state IS NOT NULL
),
SalesCTE AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_id
),
ReturnStats AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    a.full_address,
    a.ca_city,
    a.ca_state,
    COALESCE(s.total_net_profit, 0) AS total_net_profit,
    COALESCE(s.total_orders, 0) AS total_orders,
    r.total_returns,
    r.total_return_amount,
    ROW_NUMBER() OVER (PARTITION BY a.ca_city ORDER BY COALESCE(s.total_net_profit, 0) DESC) AS profit_rank
FROM 
    customer c
LEFT JOIN 
    AddressCTE a ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN 
    SalesCTE s ON a.ca_city = s.web_site_id
LEFT JOIN 
    ReturnStats r ON c.c_customer_sk = r.sr_item_sk
WHERE 
    c.c_birth_year BETWEEN 1950 AND 2000
    AND (c.c_preferred_cust_flag = 'Y' OR r.total_returns > 5)
ORDER BY 
    a.ca_state, total_net_profit DESC;
