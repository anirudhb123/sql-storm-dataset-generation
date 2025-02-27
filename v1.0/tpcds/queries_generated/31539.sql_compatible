
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        ws.customer_sk,
        ws.order_number,
        ws.sold_date_sk,
        ws.ext_sales_price,
        1 AS level
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    
    UNION ALL
    
    SELECT 
        ws.customer_sk,
        ws.order_number,
        ws.sold_date_sk,
        ws.ext_sales_price,
        sh.level + 1
    FROM 
        web_sales ws
    JOIN 
        SalesHierarchy sh ON ws.customer_sk = sh.customer_sk
    WHERE 
        ws.order_number < sh.order_number
),
AggregateSales AS (
    SELECT
        customer_sk,
        COUNT(order_number) AS total_orders,
        SUM(ext_sales_price) AS total_sales
    FROM 
        SalesHierarchy
    GROUP BY 
        customer_sk
),
TopCustomers AS (
    SELECT 
        cs.customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        as.total_orders,
        as.total_sales,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY as.total_sales DESC) AS rank
    FROM 
        customer cs
    JOIN 
        customer_demographics cd ON cs.current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AggregateSales as ON cs.customer_sk = as.customer_sk
)
SELECT 
    tc.customer_sk,
    cd.cd_gender,
    tc.total_orders,
    tc.total_sales,
    CASE 
        WHEN cd.cd_marital_status = 'M' THEN 'Married'
        ELSE 'Single/Divorced'
    END AS marital_status,
    CASE 
        WHEN tc.rank <= 10 THEN 'Top 10'
        ELSE 'Other'
    END AS customer_group
FROM 
    TopCustomers tc
JOIN 
    customer_demographics cd ON tc.customer_sk = cd.cd_demo_sk
WHERE 
    cd.cd_credit_rating IS NOT NULL
ORDER BY 
    tc.total_sales DESC;
