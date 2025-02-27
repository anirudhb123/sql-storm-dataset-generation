
WITH RankedSales AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = DATE '2022-01-01') 
                        AND (SELECT d_date_sk FROM date_dim WHERE d_date = DATE '2022-12-31')
    GROUP BY 
        ws.bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.gender,
        cd.marital_status,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
)
SELECT 
    c.c_customer_id,
    cd.gender,
    cd.marital_status,
    cs.total_sales,
    RANK() OVER (ORDER BY cs.total_sales DESC) AS overall_sales_rank
FROM 
    RankedSales cs
JOIN 
    customer c ON cs.bill_customer_sk = c.c_customer_sk
JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    (SELECT 
         sr_customer_sk, 
         COUNT(*) AS returns_count 
     FROM 
         store_returns 
     GROUP BY 
         sr_customer_sk) sr ON c.c_customer_sk = sr.sr_customer_sk
WHERE 
    cs.sales_rank = 1
    AND (cd.gender = 'F' OR cd.marital_status = 'M')
ORDER BY 
    overall_sales_rank;
