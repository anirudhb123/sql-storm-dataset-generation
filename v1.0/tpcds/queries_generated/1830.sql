
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_ship_mode_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk, ws_ship_mode_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_income_band_sk
    FROM 
        customer_demographics
),
IncomeBand AS (
    SELECT 
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        CASE 
            WHEN (ib_lower_bound IS NULL OR ib_upper_bound IS NULL) THEN 'Unknown'
            ELSE CONCAT(ib_lower_bound, '-', ib_upper_bound)
        END AS income_range
    FROM 
        income_band
),
SalesDetails AS (
    SELECT 
        cs_bill_customer_sk AS customer_id,
        SUM(cs_net_paid) AS catalog_sales,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        COUNT(DISTINCT cs_order_number) AS total_orders
    FROM 
        catalog_sales
    GROUP BY 
        cs_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    ib.income_range,
    COALESCE(ss.total_sales, 0) AS total_web_sales,
    COALESCE(sd.total_catalog_sales, 0) AS total_catalog_sales,
    CTE.sales_rank
FROM 
    customer c
LEFT JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    IncomeBand ib ON cd.cd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN 
    RankedSales ss ON c.c_customer_sk = ss.ws_bill_customer_sk AND ss.sales_rank = 1
LEFT JOIN 
    SalesDetails sd ON c.c_customer_sk = sd.customer_id
WHERE 
    (cd.cd_gender = 'F' AND cd.cd_marital_status = 'M') OR 
    (cd.cd_gender = 'M' AND sd.total_orders > 5)
ORDER BY 
    total_web_sales DESC, total_catalog_sales DESC;
