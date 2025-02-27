
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate, 
        hd.hd_income_band_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
),
SalesSummary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        cd.c_customer_id,
        ss.total_net_profit,
        ss.total_orders,
        ss.total_quantity,
        ROW_NUMBER() OVER (ORDER BY ss.total_net_profit DESC) AS rank
    FROM 
        CustomerDetails cd
    JOIN 
        SalesSummary ss ON cd.c_customer_id = ss.ws_bill_customer_sk
)
SELECT 
    tc.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    tc.total_net_profit,
    tc.total_orders,
    tc.total_quantity
FROM 
    TopCustomers tc
JOIN 
    CustomerDetails cd ON tc.c_customer_id = cd.c_customer_id
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_net_profit DESC;
