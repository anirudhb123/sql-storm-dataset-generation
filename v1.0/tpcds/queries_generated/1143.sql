
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_purchase_estimate
    FROM 
        RankedCustomers rc
    WHERE 
        rc.purchase_rank <= 10
),
SalesSummary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discounts,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    ss.total_sales,
    ss.total_discounts,
    ss.total_orders
FROM 
    TopCustomers tc
LEFT JOIN 
    SalesSummary ss ON tc.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    ss.total_sales IS NOT NULL
ORDER BY 
    total_sales DESC
LIMIT 20;

WITH IncomeDistribution AS (
    SELECT 
        h.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        household_demographics h
    LEFT JOIN 
        customer c ON h.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY 
        h.hd_income_band_sk
)
SELECT 
    id.hd_income_band_sk,
    id.customer_count,
    CASE 
        WHEN id.customer_count IS NULL THEN 'No customers'
        ELSE 'Customers present'
    END AS customer_status
FROM 
    IncomeDistribution id
WHERE 
    id.customer_count > 5
UNION ALL
SELECT 
    ib.ib_income_band_sk AS hd_income_band_sk,
    0 AS customer_count,
    'No customers' AS customer_status
FROM 
    income_band ib
WHERE 
    ib.ib_income_band_sk NOT IN (SELECT hd_income_band_sk FROM IncomeDistribution)
ORDER BY 
    hd_income_band_sk;
