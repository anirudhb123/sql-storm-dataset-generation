
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_sales_price, 
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ext_sales_price DESC) AS rnk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 0 
        AND ws.ws_quantity IS NOT NULL
),
AggregatedReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returned, 
        SUM(cr_return_amt) AS total_return_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr_item_sk
),
AddressCounts AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender, 
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        MIN(cd.cd_dep_count) AS min_dependent_count
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_gender IN ('M', 'F')
    GROUP BY 
        cd.cd_gender
)
SELECT 
    RANK() OVER (ORDER BY ac.address_count DESC) AS state_rank,
    ac.ca_state,
    ac.address_count,
    cd.avg_purchase_estimate,
    cd.min_dependent_count,
    COALESCE(rs.ws_quantity, 0) AS quantity_sold,
    CASE 
        WHEN SUM(rr.total_returned) IS NULL THEN 'No Returns'
        WHEN SUM(rr.total_returned) > 0 THEN 'Has Returns'
        ELSE 'Not Applicable'
    END AS return_status
FROM 
    AddressCounts ac
LEFT JOIN 
    CustomerDemographics cd ON ac.address_count > 0
LEFT JOIN 
    RankedSales rs ON rs.web_site_sk = ac.address_count
LEFT JOIN 
    AggregatedReturns rr ON rr.cr_item_sk = rs.web_site_sk
WHERE 
    cd.avg_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
GROUP BY 
    ac.ca_state, ac.address_count, cd.avg_purchase_estimate, cd.min_dependent_count, rs.ws_quantity
HAVING 
    COUNT(cd.cd_gender) > 1
ORDER BY 
    ac.address_count DESC, cd.avg_purchase_estimate DESC;
