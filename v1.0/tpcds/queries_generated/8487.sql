
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c 
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
        AND c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
), 
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        CASE 
            WHEN cd.cd_purchase_estimate > 2000 THEN 'High Value' 
            ELSE 'Low Value' 
        END AS customer_value
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
), 
TopCustomers AS (
    SELECT 
        cp.c_customer_id,
        cp.total_spent,
        dp.cd_gender,
        dp.cd_marital_status,
        dp.customer_value
    FROM 
        CustomerPurchases cp
    JOIN 
        Demographics dp ON cp.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_customer_sk = dp.cd_demo_sk LIMIT 1) 
    WHERE 
        cp.total_orders > 5 
    ORDER BY 
        cp.total_spent DESC
    LIMIT 10
)
SELECT 
    tc.c_customer_id,
    tc.total_spent,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.customer_value,
    COUNT(ws.ws_order_number) AS order_count
FROM 
    TopCustomers tc 
JOIN 
    web_sales ws ON tc.c_customer_id = ws.ws_bill_customer_sk
GROUP BY 
    tc.c_customer_id, 
    tc.total_spent, 
    tc.cd_gender, 
    tc.cd_marital_status,
    tc.customer_value
ORDER BY 
    total_spent DESC;
