
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_return_amt,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt) DESC) AS return_rank
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
    HAVING 
        SUM(sr_return_quantity) > 0
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS gender_purchase_rank
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate IS NOT NULL
),
ArchivedItem AS (
    SELECT 
        i_item_sk,
        i_product_name,
        i_current_price,
        i_rec_start_date,
        i_rec_end_date,
        CASE 
            WHEN i_rec_end_date < CURRENT_DATE THEN 'Archived'
            ELSE 'Active'
        END AS item_status
    FROM 
        item
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    a.i_product_name,
    r.total_returns,
    r.total_returned_quantity,
    r.total_return_amt,
    a.i_current_price,
    a.item_status,
    CASE 
        WHEN r.total_return_amt IS NULL THEN 0
        ELSE r.total_return_amt / NULLIF(r.total_returns, 0)
    END AS avg_return_amt_per_return,
    CASE 
        WHEN a.i_current_price IS NULL OR a.i_current_price = 0 THEN 'No Price'
        ELSE CAST(ROUND(((a.i_current_price - COALESCE(NULLIF(r.total_return_amt, 0), a.i_current_price)) / a.i_current_price) * 100, 2) AS varchar) || '%' 
    END AS return_percentage
FROM 
    customer c 
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    RankedReturns r ON r.sr_item_sk = (SELECT sr_item_sk FROM store_returns WHERE sr_customer_sk = c.c_customer_sk ORDER BY sr_returned_date_sk DESC LIMIT 1)
LEFT JOIN 
    ArchivedItem a ON a.i_item_sk = r.sr_item_sk
LEFT JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    a.i_rec_end_date IS NULL OR a.i_rec_end_date > CURRENT_DATE
ORDER BY 
    avg_return_amt_per_return DESC NULLS LAST
LIMIT 50;
