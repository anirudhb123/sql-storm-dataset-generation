
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_quantity) DESC) AS rn
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerWithDemographics AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY cd.cd_demo_sk DESC) AS demo_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
InventoryStatus AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_stock
    FROM 
        inventory inv
    WHERE 
        inv.inv_quantity_on_hand IS NOT NULL
    GROUP BY 
        inv.inv_item_sk
),
DateRelatedReturns AS (
    SELECT 
        d.d_date_id,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS returns_count
    FROM 
        date_dim d
    LEFT JOIN 
        store_returns sr ON d.d_date_sk = sr.sr_returned_date_sk
    WHERE 
        d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        d.d_date_id
)
SELECT 
    c.c_customer_id,
    c.cd_gender,
    r.total_returned,
    i.total_stock,
    d.total_returns,
    d.returns_count
FROM 
    CustomerWithDemographics c
JOIN 
    RankedReturns r ON c.c_customer_id = r.sr_customer_sk AND r.rn = 1
LEFT JOIN 
    InventoryStatus i ON i.inv_item_sk IN (
        SELECT 
            cr_item_sk 
        FROM 
            catalog_returns 
        WHERE 
            cr_returning_customer_sk = r.sr_customer_sk
    )
LEFT JOIN 
    DateRelatedReturns d ON d.d_date_id IN (
        SELECT 
            d.d_date_id 
        FROM 
            date_dim d 
        JOIN 
            store_returns sr ON d.d_date_sk = sr.sr_returned_date_sk 
        WHERE 
            sr.sr_customer_sk = r.sr_customer_sk
    )
WHERE 
    c.demo_rank = 1 
    AND (d.returns_count IS NULL OR d.returns_count > 5)
ORDER BY 
    r.total_returned DESC, 
    c.c_customer_id;
