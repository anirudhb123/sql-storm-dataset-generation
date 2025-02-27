
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cu.c_first_name || ' ' || cu.c_last_name AS customer_name,
        s.ss_sold_date_sk,
        SUM(s.ss_sales_price) AS total_sales
    FROM 
        customer AS c
    LEFT JOIN 
        store_sales AS s ON c.c_customer_sk = s.ss_customer_sk
    LEFT JOIN 
        customer_demographics AS cu ON c.c_current_cdemo_sk = cu.cd_demo_sk
    WHERE 
        cu.cd_gender = 'F' AND 
        (cu.cd_marital_status = 'M' OR cu.cd_marital_status IS NULL)
    GROUP BY 
        c.c_customer_sk, c.c_current_cdemo_sk, customer_name, s.ss_sold_date_sk
),
SalesRanked AS (
    SELECT 
        *,
        DENSE_RANK() OVER (PARTITION BY c_current_cdemo_sk ORDER BY total_sales DESC) AS rank
    FROM 
        SalesHierarchy
),
TopSales AS (
    SELECT 
        c_current_cdemo_sk,
        customer_name,
        SUM(total_sales) AS sales_amount
    FROM 
        SalesRanked
    WHERE 
        rank <= 3
    GROUP BY 
        c_current_cdemo_sk, customer_name
)
SELECT 
    t.c_current_cdemo_sk,
    t.customer_name,
    t.sales_amount,
    CASE 
        WHEN t.sales_amount > 10000 THEN 'High Value'
        WHEN t.sales_amount > 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM 
    TopSales AS t
JOIN 
    (SELECT DISTINCT 
        d.d_year, d.d_moy
     FROM 
        date_dim AS d 
     WHERE 
        d.d_weekend = '1' OR d.d_holiday = 'Y') AS filtered_dates ON 
        EXISTS (SELECT 1 FROM store_sales ss WHERE ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = filtered_dates.d_year AND d_moy = filtered_dates.d_moy))
ORDER BY 
    t.sales_amount DESC;
