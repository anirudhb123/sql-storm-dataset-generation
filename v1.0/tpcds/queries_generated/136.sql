
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
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
        cd.cd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    LEFT JOIN 
        income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
),
SalesWithDemographics AS (
    SELECT 
        cs.ws_bill_customer_sk,
        cs.total_sales,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.ib_lower_bound,
        cd.ib_upper_bound
    FROM 
        RankedSales cs
    JOIN 
        CustomerDemographics cd ON cs.ws_bill_customer_sk = cd.c_customer_sk
    WHERE 
        cs.sales_rank = 1
)

SELECT 
    s.ws_bill_customer_sk,
    s.total_sales,
    s.c_first_name,
    s.c_last_name,
    s.cd_gender,
    CASE 
        WHEN s.total_sales BETWEEN 0 AND 500 THEN 'Low'
        WHEN s.total_sales BETWEEN 501 AND 1500 THEN 'Medium'
        ELSE 'High'
    END AS sales_category,
    CONCAT('Income Range: $', COALESCE(CAST(s.ib_lower_bound AS VARCHAR), 'N/A'), ' - $', COALESCE(CAST(s.ib_upper_bound AS VARCHAR), 'N/A')) AS income_range
FROM 
    SalesWithDemographics s
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = (
        SELECT 
            c_current_addr_sk 
        FROM 
            customer 
        WHERE 
            c_customer_sk = s.ws_bill_customer_sk
    )
WHERE 
    ca.ca_city IS NOT NULL
ORDER BY 
    s.total_sales DESC
LIMIT 100;
