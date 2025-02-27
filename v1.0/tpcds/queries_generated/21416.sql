
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk, 
        sr_item_sk, 
        COUNT(*) AS return_count,
        SUM(sr_return_amt) AS total_return_amt,
        DENSE_RANK() OVER (PARTITION BY sr_item_sk ORDER BY COUNT(*) DESC) AS return_rank
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk, sr_item_sk
),
CustomerAddresses AS (
    SELECT 
        ca_address_sk, 
        COUNT(DISTINCT c_customer_id) AS customer_count
    FROM 
        customer_address
    JOIN 
        customer ON ca_address_sk = c_current_addr_sk
    GROUP BY 
        ca_address_sk
),
HighValueCustomers AS (
    SELECT 
        c_customer_id, 
        c_first_name, 
        c_last_name, 
        cd_credit_rating,
        cd_marital_status,
        CD_NAME = CONCAT(c_first_name, ' ', c_last_name) 
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE 
        cd_credit_rating IN ('AA', 'A') 
        AND cd_marital_status = 'M'
),
SalesData AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales_price,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    sr.return_item_sk,
    COALESCE(ca.customer_count, 0) AS address_count,
    COALESCE(hvc.CD_NAME, 'Unknown') AS high_value_customer,
    sd.total_sales_price,
    sd.order_count
FROM 
    RankedReturns sr
LEFT JOIN 
    CustomerAddresses ca ON sr_item_sk = ca.ca_address_sk 
LEFT JOIN 
    SalesData sd ON sr_item_sk = sd.ws_item_sk
LEFT JOIN 
    HighValueCustomers hvc ON hvc.c_customer_id IN (
        SELECT DISTINCT ws_ship_customer_sk 
        FROM web_sales 
        WHERE ws_item_sk = sr_item_sk
        LIMIT 1
    )
WHERE 
    (sd.sales_rank IS NULL OR sd.total_sales_price > 100.00)
    AND ca.customer_count > COALESCE(NULLIF(SELECT AVG(customer_count) FROM CustomerAddresses), 0)
ORDER BY 
    sr.return_count DESC, total_sales_price ASC;
