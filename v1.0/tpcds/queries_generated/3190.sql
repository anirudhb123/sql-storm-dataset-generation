
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid + cs.cs_net_paid + ss.ss_net_paid) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        COUNT(cd.cd_demo_sk) AS demo_count
    FROM customer_demographics cd
    GROUP BY 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_income_band_sk
),
CombinedData AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk
    FROM CustomerSales cs
    JOIN CustomerDemographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE cs.sales_rank <= 10
)
SELECT 
    c.c_last_name || ', ' || c.c_first_name AS customer_name,
    COALESCE(cs.total_web_sales, 0) AS total_web_sales,
    COALESCE(cs.total_catalog_sales, 0) AS total_catalog_sales,
    COALESCE(cs.total_store_sales, 0) AS total_store_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM CombinedData cs
LEFT JOIN income_band ib ON cs.cd_income_band_sk = ib.ib_income_band_sk
ORDER BY total_web_sales DESC, customer_name;
