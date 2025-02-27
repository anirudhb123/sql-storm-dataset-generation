
WITH SalesData AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_tax) AS total_tax,
        SUM(ss.ss_net_profit) AS total_profit
    FROM 
        store_sales ss
    JOIN 
        warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        w.w_warehouse_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_dep_count,
        SUM(sd.total_sales) AS total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        SalesData sd ON sd.w_warehouse_id IN (SELECT s.s_store_id FROM store s WHERE s.s_store_sk IN (SELECT ss.ss_store_sk FROM store_sales ss WHERE ss.ss_customer_sk = c.c_customer_sk))
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_dep_count
)
SELECT 
    cd_gender,
    cd_marital_status,
    cd_education_status,
    AVG(cd_dep_count) AS avg_dep_count,
    SUM(total_sales) AS total_sales
FROM 
    CustomerDemographics
GROUP BY 
    cd_gender, cd_marital_status, cd_education_status, cd_dep_count
ORDER BY 
    total_sales DESC
LIMIT 10;
