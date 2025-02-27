
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
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2454003 AND 2454603 -- Simulate a date range for sales
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.customer_sk,
        c.first_name,
        c.last_name,
        s.total_sales,
        s.order_count,
        ROW_NUMBER() OVER (ORDER BY s.total_sales DESC) AS rank
    FROM 
        CustomerSales s
    JOIN 
        customer c ON s.c_customer_sk = c.c_customer_sk
)
SELECT 
    t.first_name,
    t.last_name,
    t.total_sales,
    t.order_count,
    ci.cd_gender,
    ci.cd_income_band_sk,
    ih.ib_lower_bound,
    ih.ib_upper_bound
FROM 
    TopCustomers t
JOIN 
    customer_demographics ci ON t.c_customer_sk = ci.cd_demo_sk
JOIN 
    household_demographics hh ON ci.cd_demo_sk = hh.hd_demo_sk
JOIN 
    income_band ih ON hh.hd_income_band_sk = ih.ib_income_band_sk
WHERE 
    t.rank <= 10
ORDER BY 
    t.total_sales DESC;
