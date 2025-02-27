
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CustomerAddress AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_address_id, ca.ca_city, ca.ca_state, ca.ca_country
),
SalesData AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_date_sk, ws.ws_item_sk
)
SELECT 
    rc.c_customer_sk,
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    sd.total_quantity,
    sd.total_sales,
    sd.total_profit
FROM 
    RankedCustomers rc
JOIN 
    CustomerAddress ca ON rc.c_customer_sk = ca.customer_count
JOIN 
    SalesData sd ON rc.c_customer_sk = sd.ws_ship_date_sk
WHERE 
    rc.rank <= 10 
    AND ca.ca_country = 'USA'
ORDER BY 
    sd.total_profit DESC;
