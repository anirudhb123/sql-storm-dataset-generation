
WITH CustomerReturns AS (
    SELECT
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned,
        COUNT(DISTINCT cr_order_number) AS total_orders_returned
    FROM
        catalog_returns
    GROUP BY
        cr_returning_customer_sk
),
SalesData AS (
    SELECT
        ws_ship_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_ship_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_sales_price IS NOT NULL
    GROUP BY
        ws_ship_customer_sk
),
HighValueCustomers AS (
    SELECT
        customer_sk,
        total_sales,
        order_count
    FROM
        SalesData
    WHERE
        total_sales >= (SELECT AVG(total_sales) FROM SalesData)
),
CombinedReturns AS (
    SELECT
        c.c_customer_sk,
        COALESCE(cr.total_returned, 0) AS total_returned,
        COALESCE(sd.total_sales, 0) AS total_sales,
        CASE 
            WHEN COALESCE(cr.total_returned, 0) > 0 THEN 'High Return'
            WHEN COALESCE(sd.total_sales, 0) >= 1000 THEN 'High Value'
            ELSE 'Regular'
        END AS customer_category
    FROM
        customer c
    LEFT JOIN
        CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN
        SalesData sd ON c.c_customer_sk = sd.customer_sk
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    cb.total_returned,
    cb.total_sales,
    cb.customer_category,
    RANK() OVER (PARTITION BY cb.customer_category ORDER BY cb.total_sales DESC) AS category_rank
FROM 
    CombinedReturns cb
LEFT JOIN 
    customer_address ca ON cb.c_customer_sk = ca.ca_address_sk
WHERE 
    (cb.customer_category = 'High Value' AND cb.total_sales IS NOT NULL) 
    OR (cb.customer_category = 'High Return' AND cb.total_returned IS NOT NULL)
ORDER BY 
    category_rank ASC, 
    total_sales DESC;
