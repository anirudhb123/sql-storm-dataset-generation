
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
DemographicStats AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(cs.total_web_sales) AS avg_web_sales,
        AVG(cs.total_catalog_sales) AS avg_catalog_sales,
        AVG(cs.total_store_sales) AS avg_store_sales
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
SalesTrends AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    ds.cd_gender,
    ds.cd_marital_status,
    ds.avg_web_sales,
    ds.avg_catalog_sales,
    ds.avg_store_sales,
    st.total_web_sales AS yearly_web_sales,
    st.total_catalog_sales AS yearly_catalog_sales,
    st.total_store_sales AS yearly_store_sales
FROM 
    DemographicStats ds
JOIN 
    SalesTrends st ON ds.cd_demo_sk = (SELECT TOP 1 cd.cd_demo_sk FROM customer_demographics cd WHERE cd.cd_gender = ds.cd_gender AND cd.cd_marital_status = ds.cd_marital_status)
ORDER BY 
    ds.cd_gender, ds.cd_marital_status;
