
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank,
        COUNT(*) OVER (PARTITION BY ws_item_sk) AS sales_count
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
HighValueSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales_value,
        COUNT(ws_order_number) AS order_count
    FROM 
        RankedSales
    WHERE 
        price_rank = 1
    GROUP BY 
        ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_store_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    GROUP BY 
        sr_store_sk
)
SELECT 
    ca.city AS customer_city,
    SUM(COALESCE(hvs.total_sales_value, 0)) AS total_sales,
    COALESCE(cr.return_count, 0) AS total_returns,
    COALESCE(cr.total_return_value, 0) AS returns_value,
    (SUM(COALESCE(hvs.total_sales_value, 0)) - COALESCE(cr.total_return_value, 0)) AS net_revenue
FROM 
    customer_address ca
LEFT JOIN 
    HighValueSales hvs ON hvs.ws_item_sk IN (
        SELECT ws_item_sk 
        FROM web_sales 
        WHERE ws_order_number IN (
            SELECT ws_order_number 
            FROM web_sales 
            GROUP BY ws_order_number 
            HAVING COUNT(*) > 1
        )
    )
LEFT JOIN 
    CustomerReturns cr ON cr.s_store_sk = ca.ca_address_sk
GROUP BY 
    ca.city
HAVING 
    (SUM(COALESCE(hvs.total_sales_value, 0)) - COALESCE(cr.total_return_value, 0)) > 1000
ORDER BY 
    net_revenue DESC;
