
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0)) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
    ORDER BY 
        cs.total_sales DESC
    LIMIT 10
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    TopCustomers tc
JOIN 
    customer_demographics cd ON tc.c_customer_id = cd.cd_demo_sk
LEFT JOIN 
    household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
LEFT JOIN 
    income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
ORDER BY 
    tc.total_sales DESC;
