
WITH SalesSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ss.ss_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ws.ws_net_paid, 0)) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_count,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_count
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT s.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        SalesSummary s ON c.c_customer_sk = s.c_customer_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
TopSpenders AS (
    SELECT 
        customer_sk,
        ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS rnk
    FROM 
        SalesSummary
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(cd.customer_count) AS total_customers,
    COUNT(ts.customer_sk) AS top_spenders_count
FROM 
    CustomerDemographics cd
LEFT JOIN 
    TopSpenders ts ON cd.cd_demo_sk = ts.customer_sk
WHERE 
    ts.rnk <= 10
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
ORDER BY 
    total_customers DESC, cd.cd_gender;
