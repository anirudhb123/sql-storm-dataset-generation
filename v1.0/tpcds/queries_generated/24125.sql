
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_quantity) AS total_returned_quantity,
        DENSE_RANK() OVER (PARTITION BY sr_customer_sk ORDER BY COUNT(sr_ticket_number) DESC) AS rank_return
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk, sr_customer_sk
),
StoreReturnInfo AS (
    SELECT 
        sr.*,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY sr_store_sk ORDER BY sr_return_amt DESC) as rn
    FROM 
        store_returns sr
    LEFT JOIN 
        customer_address ca ON sr_addr_sk = ca.ca_address_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd.education_status,
        ib.ib_income_band_sk,
        (SELECT COUNT(*) FROM customer WHERE c_current_cdemo_sk = cd.cd_demo_sk) AS num_related_customers
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
TotalStoreSales AS (
    SELECT 
        ss_store_sk, 
        SUM(ss_net_paid) AS total_net_sales
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ss_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_store_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    d.d_date AS sales_date,
    si.ca_city,
    si.ca_state,
    ts.total_net_sales,
    rr.total_returns,
    rr.total_returned_quantity,
    CASE 
        WHEN rr.rank_return = 1 THEN 'Top Returner' 
        WHEN rr.total_returns IS NULL THEN 'No Returns' 
        ELSE 'Regular Returner' 
    END AS return_status
FROM 
    customer ci
JOIN 
    CustomerDemographics cd ON ci.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    StoreReturnInfo si ON ci.c_customer_sk = si.sr_customer_sk
JOIN 
    TotalStoreSales ts ON si.sr_store_sk = ts.ss_store_sk
LEFT JOIN 
    RankedReturns rr ON ci.c_customer_sk = rr.sr_customer_sk
JOIN 
    date_dim d ON d.d_date_sk = si.sr_returned_date_sk
WHERE 
    cd.cd_marital_status = 'M' 
    AND cd.cd_gender = 'F'
    AND (ts.total_net_sales IS NOT NULL OR rr.total_returns IS NOT NULL)
    AND si.rn = 1
ORDER BY 
    d.d_date DESC, ci.c_last_name, ci.c_first_name;
