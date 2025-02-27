
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_first_shipto_date_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
MaxSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS sales_rank
    FROM 
        CustomerSales cs
),
CustomerInfo AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cs.total_spent
    FROM 
        customer_demographics cd
    JOIN 
        CustomerSales cs ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_sk = cs.c_customer_sk)
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
)
SELECT 
    ci.cd_gender,
    ci.cd_marital_status,
    COUNT(ci.cd_purchase_estimate) AS estimate_count,
    AVG(ci.total_spent) AS avg_spent,
    COUNT(DISTINCT ms.c_customer_sk) AS high_spenders_count
FROM 
    CustomerInfo ci
LEFT JOIN 
    MaxSales ms ON ci.total_spent = ms.total_spent AND ms.sales_rank <= 10
WHERE 
    ci.total_spent > (SELECT AVG(total_spent) FROM CustomerSales)
GROUP BY 
    ci.cd_gender, ci.cd_marital_status
ORDER BY 
    estimate_count DESC, avg_spent DESC;
