
WITH OrderSummaries AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        MAX(ws_sold_date_sk) AS last_order_date
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(os.total_sales, 0) AS total_sales,
    COALESCE(os.order_count, 0) AS order_count,
    CASE 
        WHEN os.last_order_date IS NOT NULL THEN 'Frequent'
        WHEN os.total_sales > 1000 THEN 'High Roller'
        ELSE 'Casual'
    END AS customer_segment
FROM 
    CustomerDemographics cd
LEFT JOIN 
    OrderSummaries os ON cd.c_customer_sk = os.ws_bill_customer_sk
WHERE 
    cd.cd_marital_status = 'M' 
    AND cd.cd_purchase_estimate > 500 
UNION ALL
SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    0 AS total_sales,
    0 AS order_count,
    'Inactive' AS customer_segment
FROM 
    CustomerDemographics cd
WHERE 
    cd.cd_purchase_estimate <= 500
ORDER BY 
    total_sales DESC, 
    cd.c_last_name ASC;
