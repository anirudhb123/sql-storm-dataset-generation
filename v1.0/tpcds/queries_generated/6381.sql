
WITH SalesSummary AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM 
        store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2022 AND 2023
    GROUP BY 
        s.s_store_id
),
DemographicSummary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
ReturnsSummary AS (
    SELECT 
        sr.sr_store_sk,
        COUNT(sr.sr_item_sk) AS total_returns,
        SUM(sr.sr_return_amt) AS total_returned_amount
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_store_sk
),
CombinedSummary AS (
    SELECT 
        ss.s_store_id,
        ss.total_sales,
        ss.total_quantity,
        ss.unique_customers,
        ss.avg_sales_price,
        ds.cd_gender,
        ds.cd_marital_status,
        ds.avg_purchase_estimate,
        ds.total_customers,
        rs.total_returns,
        rs.total_returned_amount
    FROM 
        SalesSummary ss
        LEFT JOIN ReturnsSummary rs ON ss.s_store_id = rs.sr_store_sk
        JOIN DemographicSummary ds ON ss.unique_customers > 0
)
SELECT 
    cs.s_store_id,
    cs.total_sales,
    cs.total_quantity,
    cs.unique_customers,
    cs.avg_sales_price,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.avg_purchase_estimate,
    cs.total_customers,
    cs.total_returns,
    cs.total_returned_amount
FROM 
    CombinedSummary cs
ORDER BY 
    cs.total_sales DESC
LIMIT 10;
