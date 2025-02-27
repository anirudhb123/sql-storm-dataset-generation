
WITH AddressCTE AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca_city, ca_state ORDER BY ca_address_sk) AS city_row_num
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL AND ca_state IS NOT NULL
),
DemographicsCTE AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        COUNT(cd_demo_sk) OVER (PARTITION BY cd_gender) AS gender_count
    FROM 
        customer_demographics 
    WHERE 
        cd_purchase_estimate IS NOT NULL
),
ReturnInfo AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_qty) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS unique_returns
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
StoreSalesInfo AS (
    SELECT 
        ss_customer_sk,
        SUM(ss_sales_price) AS total_sales,
        SUM(ss_ext_discount_amt) AS total_discounts,
        COUNT(DISTINCT ss_ticket_number) AS unique_sales_tickets
    FROM 
        store_sales
    GROUP BY 
        ss_customer_sk
),
FinalReport AS (
    SELECT 
        A.ca_city,
        A.ca_state,
        D.cd_gender, 
        COUNT(DISTINCT D.cd_demo_sk) AS demographic_count,
        COALESCE(RI.total_returns, 0) AS total_returns,
        COALESCE(SI.total_sales, 0) AS total_sales,
        CASE
            WHEN COALESCE(SI.total_sales, 0) > 0 
                THEN ROUND(COALESCE(RI.total_returns, 0) * 100.0 / COALESCE(SI.total_sales, 0), 2)
            ELSE 0.00
        END AS return_rate_percentage,
        RANK() OVER (ORDER BY COUNT(DISTINCT D.cd_demo_sk) DESC) AS demographic_rank
    FROM 
        AddressCTE A
    LEFT JOIN 
        DemographicsCTE D ON A.ca_address_sk = D.cd_demo_sk
    LEFT JOIN 
        ReturnInfo RI ON RI.sr_customer_sk = D.cd_demo_sk
    LEFT JOIN 
        StoreSalesInfo SI ON SI.ss_customer_sk = D.cd_demo_sk
    GROUP BY 
        A.ca_city, A.ca_state, D.cd_gender, RI.total_returns, SI.total_sales
)
SELECT 
    ca_city,
    ca_state,
    cd_gender,
    demographic_count,
    total_returns,
    total_sales,
    return_rate_percentage
FROM 
    FinalReport
WHERE 
    (total_returns > 0 OR total_sales > 0) AND 
    (cd_gender IS NOT NULL OR demographic_count > 5)
ORDER BY 
    return_rate_percentage DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
