
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
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
        c.c_customer_id
),
MonthlySales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(total_web_sales) AS monthly_web_sales,
        SUM(total_catalog_sales) AS monthly_catalog_sales,
        SUM(total_store_sales) AS monthly_store_sales
    FROM 
        CustomerSales cs
    JOIN 
        date_dim d ON d.d_date_sk IN (
            SELECT 
                DISTINCT ws.ws_sold_date_sk 
            FROM 
                web_sales ws
            WHERE 
                cs.c_customer_id = ws.ws_bill_customer_sk
            UNION
            SELECT 
                DISTINCT cs.cs_sold_date_sk 
            FROM 
                catalog_sales cs
            WHERE 
                cs.cs_bill_customer_sk = cs.c_customer_id
            UNION
            SELECT 
                DISTINCT ss.ss_sold_date_sk 
            FROM 
                store_sales ss
            WHERE 
                ss.ss_customer_sk = cs.c_customer_id
        )
    GROUP BY 
        d.d_year, d.d_month_seq
)
SELECT 
    d.d_year,
    d.d_month_seq,
    COALESCE(SUM(monthly_web_sales), 0) AS total_web_sales,
    COALESCE(SUM(monthly_catalog_sales), 0) AS total_catalog_sales,
    COALESCE(SUM(monthly_store_sales), 0) AS total_store_sales,
    COALESCE(SUM(monthly_web_sales + monthly_catalog_sales + monthly_store_sales), 0) AS total_sales
FROM 
    MonthlySales ms
JOIN 
    date_dim d ON d.d_year = ms.d_year AND d.d_month_seq = ms.d_month_seq
GROUP BY 
    d.d_year, d.d_month_seq
ORDER BY 
    d.d_year, d.d_month_seq;
