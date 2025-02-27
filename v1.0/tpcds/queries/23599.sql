
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returns,
        COUNT(DISTINCT cr_order_number) AS unique_returns
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
), AggregateStats AS (
    SELECT 
        ca_address_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        MAX(cd_purchase_estimate) AS max_purchase_estimate,
        COALESCE(SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END), 0) AS married_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca_address_sk
)
SELECT 
    aos.ca_address_sk,
    aos.customer_count,
    aos.max_purchase_estimate,
    aos.married_count,
    rs.total_sales,
    COALESCE(crs.total_returns, 0) AS total_returns,
    COALESCE(crs.unique_returns, 0) AS unique_returns
FROM 
    AggregateStats aos
LEFT JOIN 
    RankedSales rs ON rs.ws_item_sk = (
        SELECT ws_item_sk 
        FROM web_sales 
        WHERE ws_bill_addr_sk = aos.ca_address_sk 
        LIMIT 1
    )
LEFT JOIN 
    CustomerReturns crs ON crs.cr_returning_customer_sk = (
        SELECT cr_returning_customer_sk 
        FROM catalog_returns 
        WHERE cr_returning_addr_sk = aos.ca_address_sk 
        ORDER BY cr_return_quantity DESC 
        LIMIT 1
    )
WHERE 
    (aos.customer_count > 0 AND aos.max_purchase_estimate IS NOT NULL) 
    OR 
    (aos.married_count = 0 AND crs.total_returns > 10)
ORDER BY 
    aos.customer_count DESC, 
    aos.max_purchase_estimate DESC
FETCH FIRST 100 ROWS ONLY;
