
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2459586 AND 2459586 + 30 -- Sales in a 30-day window
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
TopCustomers AS (
    SELECT 
        c.customer_id,
        cs.total_sales,
        cs.total_orders,
        cs.avg_order_value,
        cs.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
),
Top10Customers AS (
    SELECT 
        customer_id,
        total_sales,
        total_orders,
        avg_order_value,
        cd_gender
    FROM 
        TopCustomers
    WHERE 
        sales_rank <= 10
)
SELECT 
    t.customer_id,
    t.total_sales,
    t.total_orders,
    t.avg_order_value,
    t.cd_gender,
    d.d_month_seq,
    d.d_year
FROM 
    Top10Customers t
JOIN 
    date_dim d ON d.d_date_sk = 2459586 -- Matching with the date used in filtering
WHERE 
    d.d_month_seq IN (1, 2, 3) -- Filter by first quarter
ORDER BY 
    t.total_sales DESC;
