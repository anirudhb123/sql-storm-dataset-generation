
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
TopSalesByGender AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.total_sales
    FROM 
        RankedCustomers rc
    WHERE 
        rc.sales_rank = 1
)
SELECT 
    tbg.c_customer_sk,
    tbg.c_first_name,
    tbg.c_last_name,
    tbg.total_sales,
    cd.cd_education_status,
    c.company_name AS top_company_name
FROM 
    TopSalesByGender tbg
JOIN 
    customer c ON tbg.c_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    (SELECT 
         s.s_company_id, 
         SUM(ss.ss_ext_sales_price) AS total_sales_by_company
     FROM 
         store_sales ss
     JOIN 
         store s ON ss.ss_store_sk = s.s_store_sk
     GROUP BY 
         s.s_company_id
     ORDER BY 
         total_sales_by_company DESC
     LIMIT 1) AS top_company 
ON 
    c.c_company_id = top_company.s_company_id
WHERE 
    tbg.total_sales > 1000
ORDER BY 
    tbg.total_sales DESC;
