
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 0
),
FilteredAddresses AS (
    SELECT 
        ca.ca_address_id,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        faList
    FROM 
        customer_address ca
    CROSS JOIN (
        SELECT 
            STRING_AGG(DISTINCT p.p_promo_name, ', ') AS faList
        FROM 
            promotion p
    ) AS fa
),
CustomerPromoData AS (
    SELECT 
        rc.c_customer_id,
        rc.full_name,
        fa.full_address,
        fa.faList,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status
    FROM 
        RankedCustomers rc
    JOIN 
        FilteredAddresses fa ON rc.c_customer_id = fa.ca_address_id
)
SELECT 
    cp.full_name,
    cp.full_address,
    cp.faList,
    COUNT(DISTINCT rc.c_customer_id) AS customer_count,
    SUM(rc.cd_purchase_estimate) AS total_purchase_estimate
FROM 
    CustomerPromoData cp
JOIN 
    RankedCustomers rc ON cp.c_customer_id = rc.c_customer_id
WHERE 
    rc.purchase_rank <= 10
GROUP BY 
    cp.full_name, 
    cp.full_address, 
    cp.faList
ORDER BY 
    total_purchase_estimate DESC;
