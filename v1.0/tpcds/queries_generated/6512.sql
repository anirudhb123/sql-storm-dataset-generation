
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(d.d_date) AS last_purchase_date,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, ib.ib_lower_bound, ib.ib_upper_bound
),
TopCustomers AS (
    SELECT 
        c_customer_id,
        total_sales,
        order_count,
        last_purchase_date,
        cd_gender,
        cd_marital_status,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesSummary
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.order_count,
    tc.last_purchase_date,
    tc.cd_gender,
    tc.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    TopCustomers tc
JOIN 
    SalesSummary s ON tc.c_customer_id = s.c_customer_id
LEFT JOIN 
    household_demographics hd ON s.c_customer_id = hd.hd_demo_sk
LEFT JOIN 
    income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    tc.sales_rank <= 100
ORDER BY 
    total_sales DESC;
