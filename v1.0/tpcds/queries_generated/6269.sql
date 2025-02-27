
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(d.d_date) AS last_purchase_date
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.customer_id,
        cs.total_sales,
        cs.order_count,
        cs.last_purchase_date,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales AS cs
    JOIN 
        customer AS c ON cs.c_customer_id = c.c_customer_id
)
SELECT 
    tc.customer_id,
    tc.total_sales,
    tc.order_count,
    tc.last_purchase_date,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    ib.ib_lower_bound AS income_lower,
    ib.ib_upper_bound AS income_upper
FROM 
    TopCustomers AS tc
JOIN 
    customer_demographics AS cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
JOIN 
    household_demographics AS hd ON hd.hd_demo_sk = cd.cd_demo_sk
JOIN 
    income_band AS ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    total_sales DESC;
