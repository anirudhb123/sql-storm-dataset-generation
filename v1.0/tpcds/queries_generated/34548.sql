
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        SUM(ss_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales 
    JOIN 
        store ON store_sales.ss_store_sk = store.s_store_sk 
    WHERE 
        ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        s_store_sk, s_store_name
    
    UNION ALL
    
    SELECT 
        sh.s_store_sk,
        sh.s_store_name,
        sh.total_sales + COALESCE(ss.total_sales, 0),
        ROW_NUMBER() OVER (PARTITION BY sh.s_store_sk ORDER BY (sh.total_sales + COALESCE(ss.total_sales, 0)) DESC) AS sales_rank
    FROM 
        SalesHierarchy sh
    LEFT JOIN 
        (SELECT 
             ss_store_sk, 
             SUM(ss_net_paid) AS total_sales 
         FROM 
             store_sales 
         GROUP BY 
             ss_store_sk) ss ON sh.s_store_sk = ss.ss_store_sk
    WHERE 
        sh.sales_rank < 5
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_income_band_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_income_band_sk
),
TopCustomers AS (
    SELECT 
        cd.c_customer_id,
        cd.cd_gender,
        cd.cd_income_band_sk,
        cd.total_orders,
        cd.total_spent,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_income_band_sk ORDER BY cd.total_spent DESC) AS customer_rank
    FROM 
        CustomerDetails cd
)
SELECT 
    sh.s_store_name,
    tc.c_customer_id,
    tc.cd_gender,
    tc.total_orders,
    tc.total_spent,
    CASE 
        WHEN tc.cd_income_band_sk IS NULL THEN 'Not Specified'
        ELSE (SELECT ib_lower_bound || '-' || ib_upper_bound FROM income_band WHERE ib_income_band_sk = tc.cd_income_band_sk)
    END AS income_band_range
FROM 
    SalesHierarchy sh
JOIN 
    TopCustomers tc ON tc.total_spent > 1000
WHERE 
    sh.sales_rank <= 5
ORDER BY 
    sh.total_sales DESC, 
    tc.total_spent DESC;
