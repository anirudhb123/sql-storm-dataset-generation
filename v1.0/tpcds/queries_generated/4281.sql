
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
RankedCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        cs.sales_rank,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other' 
        END AS gender
    FROM 
        CustomerSales cs
    LEFT JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
)
SELECT 
    rc.c_customer_id,
    rc.c_first_name,
    rc.c_last_name,
    rc.total_sales,
    rc.order_count,
    rc.gender
FROM 
    RankedCustomers rc
WHERE 
    rc.sales_rank <= 10
UNION ALL
SELECT 
    'N/A' AS c_customer_id,
    'Aggregate' AS c_first_name,
    NULL AS c_last_name,
    SUM(total_sales) AS total_sales,
    SUM(order_count) AS order_count,
    NULL AS gender
FROM 
    RankedCustomers
WHERE 
    sales_rank > 10
ORDER BY 
    total_sales DESC;
