
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COUNT(ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_net_paid_inc_tax) AS total_revenue
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name
    UNION ALL
    SELECT 
        ch.c_customer_sk,
        ch.c_customer_id,
        ch.c_first_name,
        ch.c_last_name,
        COUNT(ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_net_paid_inc_tax) AS total_revenue
    FROM 
        SalesHierarchy ch
    JOIN 
        customer c ON c.c_current_cdemo_sk = ch.c_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        ch.c_customer_sk, ch.c_customer_id, ch.c_first_name, ch.c_last_name
),
CustomerStats AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(CASE WHEN sh.total_sales > 0 THEN sh.total_sales ELSE 0 END) AS sales_count,
        SUM(sh.total_revenue) AS total_revenue,
        AVG(sh.total_revenue) AS avg_revenue
    FROM 
        customer_demographics cd
    LEFT JOIN 
        SalesHierarchy sh ON cd.cd_demo_sk = sh.c_customer_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
MaxSales AS (
    SELECT 
        MAX(total_revenue) AS max_revenue
    FROM 
        CustomerStats
)
SELECT 
    cs.cd_gender,
    cs.cd_marital_status,
    cs.sales_count,
    cs.total_revenue,
    cs.avg_revenue,
    CASE 
        WHEN cs.total_revenue IS NULL THEN 'No Sales'
        WHEN cs.total_revenue = ms.max_revenue THEN 'Top Sales'
        ELSE 'Regular Sales'
    END AS sales_category
FROM 
    CustomerStats cs
CROSS JOIN 
    MaxSales ms
WHERE 
    cs.sales_count > 0
ORDER BY 
    cs.total_revenue DESC;
