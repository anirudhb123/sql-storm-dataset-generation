
WITH RECURSIVE CustomerSales AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk > (SELECT MAX(d_date_sk) 
                               FROM date_dim 
                               WHERE d_year = 2022)
    GROUP BY 
        c_customer_sk, c_first_name, c_last_name
),
SalesSummary AS (
    SELECT 
        cs.c_first_name,
        cs.c_last_name,
        COALESCE(cs.total_sales, 0) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY COALESCE(cs.total_sales, 0) DESC) AS rank_total_sales
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        (SELECT 
            w_company_name, 
            SUM(ss_ext_sales_price) as warehouse_sales
         FROM 
            store s
         JOIN 
            store_sales ss ON s.s_store_sk = ss.ss_store_sk
         GROUP BY 
            w_company_name 
         HAVING 
            SUM(ss_ext_sales_price) > 1000) w ON w.company_name = cs.c_first_name
)
SELECT 
    ss.c_first_name, 
    ss.c_last_name, 
    ss.total_sales, 
    COALESCE(ss.warehouse_sales, 0) AS warehouse_sales,
    (ss.total_sales - COALESCE(ss.warehouse_sales, 0)) AS adjusted_sales
FROM 
    SalesSummary ss
WHERE 
    ss.rank_total_sales <= 10
ORDER BY 
    adjusted_sales DESC;
