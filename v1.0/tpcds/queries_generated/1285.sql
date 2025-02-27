
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank,
        CASE 
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High Value'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_segment
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
StoreSales AS (
    SELECT 
        ss.s_store_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        AVG(ss.ss_discount_amt) AS avg_discount,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk BETWEEN 1 AND 1000
    GROUP BY 
        ss.s_store_sk
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk, 
        cs.c_first_name, 
        cs.c_last_name,
        ss.total_sales,
        ss.avg_discount,
        ss.total_transactions
    FROM 
        CustomerStats cs
    JOIN 
        StoreSales ss ON cs.c_customer_sk = ss.s_store_sk
    WHERE 
        cs.customer_value_segment = 'High Value'
)
SELECT 
    hvc.c_first_name, 
    hvc.c_last_name,
    hvc.total_sales,
    hvc.avg_discount,
    hvc.total_transactions,
    COALESCE(dd.d_day_name, 'Unknown') AS sale_day_name,
    SUM(COALESCE(ws.ws_net_profit, 0)) AS total_net_profit
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    web_sales ws ON hvc.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
GROUP BY 
    hvc.c_first_name, 
    hvc.c_last_name, 
    hvc.total_sales, 
    hvc.avg_discount, 
    hvc.total_transactions,
    dd.d_day_name
ORDER BY 
    hvc.total_sales DESC, 
    hvc.c_last_name ASC;
