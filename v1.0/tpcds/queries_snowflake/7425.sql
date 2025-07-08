
WITH CustomerStatistics AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(DATEDIFF(CURRENT_DATE, DATEADD(YEAR, -c.c_birth_year, CURRENT_DATE)) / 365.25) AS avg_age,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_purchased
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.total_sales,
        cs.total_orders,
        cs.avg_age,
        cs.unique_items_purchased,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerStatistics cs
)
SELECT 
    tc.c_customer_id,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_sales,
    tc.total_orders,
    tc.avg_age,
    tc.unique_items_purchased
FROM 
    TopCustomers tc
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
