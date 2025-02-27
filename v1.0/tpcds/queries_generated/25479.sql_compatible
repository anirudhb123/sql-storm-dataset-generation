
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        rc.c_customer_id,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_purchase_estimate
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rank <= 10
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_profit,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.ws_order_number) AS total_profit_per_order
    FROM 
        web_sales ws
    JOIN 
        TopCustomers tc ON ws.ws_bill_customer_sk = tc.c_customer_id
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    COUNT(DISTINCT sd.ws_order_number) AS total_orders,
    SUM(sd.total_profit_per_order) AS overall_profit
FROM 
    TopCustomers tc
LEFT JOIN 
    SalesData sd ON tc.c_customer_id = sd.ws_bill_customer_sk
GROUP BY 
    tc.c_first_name, 
    tc.c_last_name, 
    tc.cd_gender, 
    tc.cd_marital_status
ORDER BY 
    overall_profit DESC;
