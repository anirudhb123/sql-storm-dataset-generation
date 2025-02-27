
WITH RECURSIVE RankedReturns AS (
    SELECT 
        sr_returned_date_sk, 
        sr_item_sk, 
        sr_return_quantity, 
        sr_return_amt,
        ROW_NUMBER() OVER(PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate IS NOT NULL
),
ItemDetails AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        COALESCE(i_size, 'N/A') AS adjusted_size,
        CASE 
            WHEN i_current_price < 0 THEN 0
            ELSE i_current_price
        END AS safe_price
    FROM 
        item
),
InventoryCounts AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory
    WHERE 
        inv_quantity_on_hand > 0
    GROUP BY 
        inv_item_sk
)
SELECT 
    c.c_customer_id, 
    cd.cd_gender, 
    ir.r_reason_desc,
    SUM(rr.sr_return_quantity) AS total_returned,
    SUM(rr.sr_return_amt) AS total_return_amount,
    COUNT(DISTINCT rr.sr_returned_date_sk) AS different_return_dates,
    STRING_AGG(DISTINCT id.i_item_desc, ', ') AS item_descriptions
FROM 
    customer AS c
LEFT JOIN 
    CustomerDemographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    RankedReturns AS rr ON rr.rn = 1 AND rr.sr_item_sk IN (SELECT i_item_sk FROM ItemDetails)
LEFT JOIN 
    ItemDetails AS id ON rr.sr_item_sk = id.i_item_sk
LEFT JOIN 
    reason AS ir ON rr.sr_reason_sk = ir.r_reason_sk
LEFT JOIN 
    InventoryCounts AS ic ON ic.inv_item_sk = rr.sr_item_sk
WHERE 
    c.c_birth_year IS NOT NULL
    AND c.c_birth_month IN (SELECT d_moy FROM date_dim WHERE d_holiday = 'Y')
    AND cd.cd_marital_status IN ('M', 'S')
    AND (id.adjusted_size IS NOT NULL OR id.i_current_price > 100)
    AND (rr.total_returned IS NULL OR rr.total_returned > 0)
GROUP BY 
    c.c_customer_id, cd.cd_gender, ir.r_reason_desc
HAVING 
    SUM(rr.sr_return_quantity) >= 5 OR COUNT(DISTINCT rr.sr_returned_date_sk) > 1
ORDER BY 
    total_return_amount DESC;
