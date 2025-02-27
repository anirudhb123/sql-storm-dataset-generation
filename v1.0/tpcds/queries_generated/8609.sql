
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_customer_id, 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451000 AND 2452000  -- Example date range
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    rc.c_customer_id,
    rc.cd_gender,
    sd.total_profit,
    sd.total_orders,
    sd.total_quantity
FROM 
    RankedCustomers rc
LEFT JOIN 
    SalesData sd ON rc.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    rc.rn <= 10
ORDER BY 
    total_profit DESC;
