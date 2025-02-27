
WITH RankedSales AS (
    SELECT 
        w.w_warehouse_name,
        s.s_store_name,
        ss.ss_sold_date_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_sold_date_sk ORDER BY SUM(ss.ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    JOIN 
        warehouse w ON s.s_company_id = w.w_warehouse_sk
    WHERE 
        ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        w.w_warehouse_name, 
        s.s_store_name, 
        ss.ss_sold_date_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        CD.cd_marital_status,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_first_shipto_date_sk > 0
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    r.w_warehouse_name,
    r.s_store_name,
    r.ss_sold_date_sk,
    r.total_quantity,
    r.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(NULLIF(cd.customer_count, 0), 'No Customers') AS customer_count
FROM 
    RankedSales r
LEFT JOIN 
    CustomerDemographics cd ON r.ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales ss WHERE ss.ss_customer_sk IS NOT NULL)
WHERE 
    r.sales_rank <= 5
ORDER BY 
    r.ss_sold_date_sk, 
    r.total_sales DESC;
