
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_state = 'CA'
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        csc.c_customer_id,
        csc.total_sales,
        csc.order_count,
        DENSE_RANK() OVER (ORDER BY csc.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales csc
),
DateRange AS (
    SELECT 
        d.d_date,
        d.d_year
    FROM 
        date_dim d
    WHERE 
        d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
),
SalesWithDemographics AS (
    SELECT 
        tc.c_customer_id,
        tc.total_sales,
        tc.order_count,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM 
        TopCustomers tc
    JOIN 
        customer_demographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_id = tc.c_customer_id)
    JOIN 
        household_demographics hd ON hd.hd_demo_sk = (SELECT c.c_current_hdemo_sk FROM customer c WHERE c.c_customer_id = tc.c_customer_id)
)
SELECT 
    swd.c_customer_id,
    swd.total_sales,
    swd.order_count,
    swd.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(dr.d_date) AS active_year_days
FROM 
    SalesWithDemographics swd
JOIN 
    income_band ib ON swd.hd_income_band_sk = ib.ib_income_band_sk
JOIN 
    DateRange dr ON dr.d_year = EXTRACT(YEAR FROM CURRENT_DATE)
WHERE 
    swd.total_sales > 1000
GROUP BY 
    swd.c_customer_id, 
    swd.total_sales, 
    swd.order_count, 
    swd.cd_gender, 
    ib.ib_lower_bound, 
    ib.ib_upper_bound
ORDER BY 
    swd.total_sales DESC;
