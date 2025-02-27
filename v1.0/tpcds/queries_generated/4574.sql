
WITH CustomerRanked AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_income_band_sk,
        cd.cd_marital_status,
        RANK() OVER (PARTITION BY cd.cd_income_band_sk ORDER BY cd.cd_purchase_estimate DESC) as income_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
HighIncomeCustomers AS (
    SELECT 
        cr.c_customer_id,
        cr.cd_gender,
        cr.cd_marital_status
    FROM 
        CustomerRanked cr
    WHERE 
        cr.income_rank <= 10
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
HighSpenders AS (
    SELECT 
        s.ws_bill_customer_sk,
        hs.c_customer_id,
        hs.cd_gender,
        hs.cd_marital_status,
        s.total_sales,
        s.order_count
    FROM 
        SalesSummary s
    JOIN 
        HighIncomeCustomers hs ON s.ws_bill_customer_sk = hs.c_customer_id
    WHERE 
        s.total_sales > 1000
)
SELECT 
    h.c_customer_id,
    h.cd_gender,
    h.cd_marital_status,
    h.total_sales,
    h.order_count,
    COALESCE(NULLIF(h.total_sales, 0), 'No sales') AS sales_or_zero
FROM 
    HighSpenders h
ORDER BY 
    h.total_sales DESC
LIMIT 20;
