
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) AS address_rank
    FROM 
        customer_address
),
FilteredAddresses AS (
    SELECT 
        full_address,
        COUNT(*) AS address_count
    FROM 
        RankedAddresses
    WHERE 
        address_rank <= 5
    GROUP BY 
        full_address
)
SELECT 
    fa.full_address,
    fa.address_count,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate
FROM 
    FilteredAddresses fa
JOIN 
    customer c ON c.c_current_addr_sk IN (SELECT ca_address_sk FROM customer_address WHERE CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) = fa.full_address)
JOIN 
    customer_demographics cd ON c.c_customer_sk = cd.cd_demo_sk
WHERE 
    cd.cd_gender = 'M'
    AND cd.cd_purchase_estimate > 1000
ORDER BY 
    fa.address_count DESC, cd.cd_purchase_estimate DESC;
