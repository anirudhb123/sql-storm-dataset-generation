
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        rc.* 
    FROM 
        RankedCustomers rc 
    WHERE 
        rc.rn <= 5
),
SalesDetails AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_ship_mode_sk,
        DATEADD(DAY, 7, d.d_date) AS ReturnWindow,
        CASE 
            WHEN ws.ws_net_paid > 100 THEN 'High Value'
            WHEN ws.ws_net_paid BETWEEN 50 AND 100 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS ValueCategory
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    sd.ws_order_number,
    sd.ws_net_paid,
    sd.ValueCategory,
    CASE 
        WHEN sd.ws_net_paid IS NULL THEN 'No Sales'
        ELSE 'Sales Found'
    END AS SalesStatus,
    COALESCE(SUM(sd.ws_net_paid) OVER (PARTITION BY sd.ValueCategory ORDER BY sd.ws_net_paid DESC), 0) AS CumulativeSales
FROM 
    TopCustomers tc
LEFT JOIN 
    SalesDetails sd ON tc.c_customer_sk = sd.ws_ship_customer_sk
WHERE 
    sd.ws_net_paid IS NOT NULL
    OR EXISTS (SELECT 1 FROM store_returns sr WHERE sr.sr_returned_date_sk = sd.ws_sold_date_sk AND sr.sr_customer_sk = tc.c_customer_sk)
ORDER BY 
    tc.c_last_name, 
    tc.c_first_name,
    sd.ws_order_number;
