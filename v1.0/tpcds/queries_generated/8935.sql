
WITH SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_discount_amt) AS total_discounts,
        SUM(ws_ext_tax) AS total_taxes
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2459639 AND 2459647  -- Example date range within valid date_dim 
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        SUM(ss.net_paid) AS store_sales_total
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
),
TopCustomers AS (
    SELECT 
        sd.ws_bill_customer_sk,
        sd.total_sales,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.store_sales_total
    FROM 
        SalesSummary sd
    JOIN 
        CustomerDetails cd ON sd.ws_bill_customer_sk = cd.c_customer_sk
    WHERE 
        sd.total_sales > 10000  -- Filter for top customers with substantial sales
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_income_band_sk,
    tc.total_sales,
    tc.total_orders,
    tc.store_sales_total,
    ROUND((tc.total_sales + tc.store_sales_total) / NULLIF(tc.total_orders, 0), 2) AS avg_sales_per_order,
    tc.total_discounts,
    tc.total_taxes
FROM 
    TopCustomers tc
ORDER BY 
    tc.total_sales DESC
LIMIT 10;  -- Retrieve the top 10 customers based on total sales
