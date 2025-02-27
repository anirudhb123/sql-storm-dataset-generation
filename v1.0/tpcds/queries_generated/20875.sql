
WITH address_summary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_zip) AS unique_zip_count,
        AVG(ca_gmt_offset) AS avg_gmt_offset
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
customer_summary AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        SUM(cd_purchase_estimate) AS total_estimated_purchases,
        MAX(cd_dep_count) AS max_dependents
    FROM 
        customer 
        JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
sales_rank AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws 
    GROUP BY 
        ws.bill_customer_sk
),
return_summary AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
lookup AS (
    SELECT
        ir.ib_lower_bound,
        ir.ib_upper_bound,
        CASE
            WHEN cd_purchase_estimate IS NULL THEN 'UNKNOWN'
            WHEN cd_purchase_estimate >= ib_lower_bound AND cd_purchase_estimate <= ib_upper_bound THEN 'IN_RANGE'
            ELSE 'OUT_OF_RANGE'
        END AS purchase_status
    FROM 
        income_band ir
        LEFT JOIN customer_demographics cd ON cd_purchase_estimate IS NOT NULL
)
SELECT 
    a.ca_state,
    a.unique_zip_count,
    a.avg_gmt_offset,
    c.cd_gender,
    c.customer_count,
    c.total_estimated_purchases,
    c.max_dependents,
    s.total_sales,
    r.total_returns,
    r.total_return_amt,
    l.purchase_status
FROM 
    address_summary a 
JOIN 
    customer_summary c ON c.customer_count > 0
JOIN 
    sales_rank s ON c.customer_count > 10
FULL OUTER JOIN 
    return_summary r ON r.total_returns > 5
LEFT JOIN 
    lookup l ON l.ib_upper_bound IS NOT NULL
WHERE 
    (a.unique_zip_count IS NULL OR a.avg_gmt_offset > 0)
    AND (c.max_dependents IS NOT NULL OR s.total_sales < 1000)
ORDER BY 
    a.ca_state, c.cd_gender DESC;
