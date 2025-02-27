
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank,
        MAX(ws.ws_ext_sales_price) OVER (PARTITION BY ws.ws_item_sk) AS max_sales_price,
        (CASE 
            WHEN MAX(ws.ws_ext_sales_price) OVER (PARTITION BY ws.ws_item_sk) IS NULL THEN 'Price Unknown' 
            ELSE 'Known Price' 
         END) AS price_status
    FROM 
        web_sales ws
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_purchase_estimate > 5000
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_marital_status, cd.cd_purchase_estimate
    HAVING 
        COUNT(DISTINCT ws.ws_order_number) > 2
),
CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk, 
        COUNT(DISTINCT cr.returning_addr_sk) AS distinct_addresses,
        SUM(cr.return_quantity) AS total_returned_quantity
    FROM 
        catalog_returns cr
    WHERE 
        cr.return_quantity IS NOT NULL
    GROUP BY 
        cr.returning_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    HVC.total_orders,
    HVC.cd_purchase_estimate,
    COALESCE(CR.total_returned_quantity, 0) AS total_returns,
    COALESCE(CR.distinct_addresses, 0) AS distinct_return_addresses,
    R.sold_item_sk,
    R.ws_sales_price,
    R.price_status
FROM 
    customer c
LEFT JOIN 
    HighValueCustomers HVC ON c.c_customer_sk = HVC.c_customer_sk
LEFT JOIN 
    CustomerReturns CR ON c.c_customer_sk = CR.returning_customer_sk
LEFT JOIN 
    RankedSales R ON R.ws_item_sk = CR.returning_customer_sk
WHERE 
    (HVC.cd_marital_status = 'M' OR HVC.cd_marital_status IS NULL)
    AND (HVC.total_orders IS NOT NULL OR CR.total_returns > 0)
ORDER BY 
    HVC.cd_purchase_estimate DESC, 
    total_returns DESC NULLS LAST
LIMIT 100
OFFSET 50;
