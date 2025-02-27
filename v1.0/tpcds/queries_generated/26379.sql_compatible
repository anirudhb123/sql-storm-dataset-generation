
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender, 
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_ship_date_sk,
        si.i_item_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        item si ON ws.ws_item_sk = si.i_item_sk
    GROUP BY 
        ws.ws_ship_date_sk, si.i_item_id
),
SalesSummary AS (
    SELECT 
        dd.d_date,
        sd.i_item_id, 
        SUM(sd.total_sales) AS daily_sales,
        SUM(sd.total_orders) AS daily_orders
    FROM 
        date_dim dd
    JOIN 
        SalesData sd ON dd.d_date_sk = sd.ws_ship_date_sk
    GROUP BY 
        dd.d_date, sd.i_item_id
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ss.d_date,
    ss.i_item_id,
    ss.daily_sales,
    ss.daily_orders,
    RANK() OVER (PARTITION BY ci.c_customer_sk ORDER BY ss.daily_sales DESC) AS sales_rank
FROM 
    CustomerInfo ci
JOIN 
    SalesSummary ss ON ci.c_customer_sk = ss.i_item_id
WHERE 
    ci.cd_gender = 'F' AND ci.cd_marital_status = 'M' 
ORDER BY 
    ci.full_name, ss.d_date;
