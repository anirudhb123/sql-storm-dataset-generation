
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 50000
), 
SalesData AS (
    SELECT 
        ws.ws_ship_date_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_date_sk
), 
ReturnData AS (
    SELECT 
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        sr_store_sk
    FROM 
        store_returns sr
    GROUP BY 
        sr_store_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(sd.total_net_profit) AS total_net_profit,
    SUM(sd.total_orders) AS total_orders,
    SUM(rd.total_returns) AS total_returns,
    SUM(rd.total_return_amount) AS total_return_amount,
    COUNT(DISTINCT cs.c_customer_sk) AS unique_customers,
    AVG(cs.cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    CustomerStats cs
JOIN 
    SalesData sd ON sd.ws_ship_date_sk = date_dim.d_date_sk
JOIN 
    ReturnData rd ON rd.sr_store_sk = sd.ws_warehouse_sk
JOIN 
    customer_address ca ON cs.c_customer_sk = ca.ca_address_sk
LEFT OUTER JOIN 
    date_dim ON cs.c_customer_sk = date_dim.d_date_sk
WHERE 
    date_dim.d_date BETWEEN '2022-01-01' AND '2023-01-01'
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT cs.c_customer_sk) > 100
ORDER BY 
    total_net_profit DESC
LIMIT 10;
