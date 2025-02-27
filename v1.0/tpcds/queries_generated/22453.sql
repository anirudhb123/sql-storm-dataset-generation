
WITH RankedReturns AS (
    SELECT 
        sr_return_quantity,
        sr_item_sk,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk) AS rnk
    FROM 
        store_returns
    WHERE 
        sr_return_quantity IS NOT NULL
),
AggregateSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        CASE 
            WHEN cd_marital_status = 'M' THEN 'Married'
            WHEN cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        COUNT(cd_dep_count) OVER (PARTITION BY cd_gender) AS dependents_count
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate IS NOT NULL
),
SalesTracking AS (
    SELECT 
        ss_item_sk,
        SUM(ss_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss_ticket_number) AS unique_sales,
        COALESCE(SUM(ss_ext_discount_amt), 0) AS total_discounts
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    ca.ca_city,
    COALESCE(ar.total_quantity, 0) AS return_total,
    COALESCE(st.total_store_sales, 0) AS sales_total,
    COALESCE(ar.rnk, 0) AS return_rank,
    cd.gender,
    cd.marital_status,
    SUM(CASE 
        WHEN cd.dep_count IS NULL THEN 1 
        ELSE cd.dep_count 
    END) AS total_dependents, 
    CASE 
        WHEN cd.dep_count IS NULL THEN 'Unknown'
        ELSE 'Known'
    END AS dependent_status
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    RankedReturns ar ON ar.sr_item_sk = c.c_customer_sk AND ar.rnk = 1
LEFT JOIN 
    SalesTracking st ON st.ss_item_sk = c.c_customer_sk
JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    COALESCE(c.c_birth_year, 0) BETWEEN 1980 AND 1990
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ar.total_quantity, 
    st.total_store_sales, 
    ar.rnk, 
    cd.gender, 
    cd.marital_status, 
    cd.dep_count
ORDER BY 
    total_store_sales DESC, 
    return_total DESC;
