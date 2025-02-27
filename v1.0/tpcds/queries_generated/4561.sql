
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        AVG(ws.ws_sales_price) AS avg_item_price
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
TopSpenders AS (
    SELECT 
        cs.c_customer_id,
        cs.total_spent,
        cs.avg_item_price,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSales)
)
SELECT 
    ds.cg_gender,
    ds.cd_marital_status,
    SUM(ts.total_spent) AS total_spent_by_demographics,
    COUNT(ts.c_customer_id) AS number_of_top_spenders
FROM 
    TopSpenders ts
JOIN 
    CustomerDemographics ds ON ts.c_customer_id = ds.customer_count
WHERE 
    ds.customer_count IS NOT NULL
GROUP BY 
    ds.cd_gender, ds.cd_marital_status
ORDER BY 
    total_spent_by_demographics DESC
LIMIT 10;
