
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS rnk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
),
TotalSales AS (
    SELECT 
        web_site_sk,
        SUM(ws_sales_price) AS total_sales
    FROM 
        RankedSales
    WHERE 
        rnk <= 10
    GROUP BY 
        web_site_sk
),
CustomerReturnStats AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(*) AS total_returns,
        SUM(wr_return_amt) AS total_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
)
SELECT 
    c.c_customer_id,
    COALESCE(cs.total_sales, 0) AS web_sales_last_30_days,
    COALESCE(cr.total_returns, 0) AS total_returns,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate
FROM 
    customer c
LEFT JOIN 
    TotalSales cs ON c.c_customer_sk = cs.web_site_sk
LEFT JOIN 
    CustomerReturnStats cr ON c.c_customer_sk = cr.wr_returning_customer_sk
JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    (cd.cd_marital_status = 'M' OR cd.cd_gender = 'F')
    AND c.c_birth_year IS NOT NULL
    AND (c.c_birth_month BETWEEN 1 AND 12 OR c.c_birth_month IS NULL)
ORDER BY 
    web_sales_last_30_days DESC, 
    total_returns DESC;
