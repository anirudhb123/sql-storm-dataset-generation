
WITH YearlySales AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        SUM(cs.cs_net_paid_inc_tax) AS total_catalog_sales,
        SUM(ss.ss_net_paid_inc_tax) AS total_store_sales
    FROM 
        date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        d.d_year
),
SalesByCustomer AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_net_paid_inc_tax) AS web_sales, 
        SUM(cs.cs_net_paid_inc_tax) AS catalog_sales, 
        SUM(ss.ss_net_paid_inc_tax) AS store_sales, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
AggregatedSales AS (
    SELECT 
        s.c_customer_id,
        s.web_sales,
        s.catalog_sales,
        s.store_sales,
        CASE 
            WHEN s.web_sales > 1000 THEN 'High Web'
            WHEN s.web_sales BETWEEN 500 AND 1000 THEN 'Medium Web'
            ELSE 'Low Web' 
        END AS web_sales_category,
        CASE 
            WHEN s.catalog_sales > 1000 THEN 'High Catalog'
            WHEN s.catalog_sales BETWEEN 500 AND 1000 THEN 'Medium Catalog'
            ELSE 'Low Catalog' 
        END AS catalog_sales_category,
        CASE 
            WHEN s.store_sales > 1000 THEN 'High Store'
            WHEN s.store_sales BETWEEN 500 AND 1000 THEN 'Medium Store'
            ELSE 'Low Store' 
        END AS store_sales_category
    FROM 
        SalesByCustomer s
)
SELECT 
    a.c_customer_id,
    a.web_sales,
    a.catalog_sales,
    a.store_sales,
    a.web_sales_category,
    a.catalog_sales_category,
    a.store_sales_category,
    y.total_web_sales,
    y.total_catalog_sales,
    y.total_store_sales
FROM 
    AggregatedSales a
JOIN 
    YearlySales y ON 1=1
WHERE 
    y.total_web_sales > 5000
ORDER BY 
    a.web_sales DESC, a.catalog_sales DESC, a.store_sales DESC
LIMIT 100;
