
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        c.* 
    FROM 
        CustomerSales cs
    JOIN 
        customer_address ca ON cs.c_customer_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
        AND cd.cd_credit_rating = 'High'
),
SalesByMonth AS (
    SELECT 
        d.d_year, 
        d.d_month_seq, 
        SUM(ws.ws_net_paid) AS monthly_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
),
TopMonths AS (
    SELECT 
        d.d_year, 
        d.d_month_seq, 
        monthly_sales,
        RANK() OVER (ORDER BY monthly_sales DESC) AS sales_rank
    FROM 
        SalesByMonth
)
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    SUM(swm.monthly_sales) AS high_value_customer_monthly_sales
FROM 
    HighValueCustomers c
JOIN 
    TopMonths swm ON swm.sales_rank <= 5
GROUP BY 
    c.c_first_name, c.c_last_name
ORDER BY 
    high_value_customer_monthly_sales DESC
LIMIT 10;
