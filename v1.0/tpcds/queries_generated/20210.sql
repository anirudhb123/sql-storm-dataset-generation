
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_ticket_number,
        SUM(sr_return_quantity) AS total_returned_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) AS rn
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk, sr_item_sk, sr_ticket_number
), LostReturns AS (
    SELECT 
        rr.sr_item_sk,
        ISNULL(SUM(sr_returned_quantity), 0) AS lost_quantity
    FROM 
        RankedReturns rr
    LEFT JOIN 
        store_sales ss ON rr.sr_item_sk = ss.ss_item_sk AND rr.sr_ticket_number = ss.ss_ticket_number
    WHERE 
        rr.rn = 1
    GROUP BY 
        rr.sr_item_sk
), CustomerInsights AS (
    SELECT 
        c.c_customer_id,
        d.d_year,
        COUNT(DISTINCT CASE WHEN c.c_birth_day IS NULL THEN 1 ELSE NULL END) AS null_birth_day_count,
        AVG(hd.hd_vehicle_count) AS average_vehicle_count,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_id, d.d_year
)
SELECT 
    ci.c_customer_id,
    SUM(COALESCE(lr.lost_quantity, 0)) AS total_lost_returns,
    ROUND(AVG(ci.average_vehicle_count), 2) AS avg_vehicle_count,
    MAX(ci.max_purchase_estimate) AS highest_estimate,
    CASE 
        WHEN MAX(ci.null_birth_day_count) > 0 THEN 'Contains Null'
        ELSE 'No Null'
    END AS null_birth_day_status
FROM 
    CustomerInsights ci
LEFT JOIN 
    LostReturns lr ON ci.c_customer_id = lr.sr_item_sk::text -- assume sr_item_sk represents customer for this query's context
GROUP BY 
    ci.c_customer_id
HAVING 
    SUM(COALESCE(lr.lost_quantity, 0)) > 5
ORDER BY 
    total_lost_returns DESC, avg_vehicle_count ASC;
