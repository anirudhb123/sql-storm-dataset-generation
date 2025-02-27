
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS rn
    FROM web_sales
    UNION ALL
    SELECT
        cs_sold_date_sk,
        cs_item_sk,
        cs_sales_price,
        cs_quantity,
        cs_net_paid,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_sold_date_sk) AS rn
    FROM catalog_sales
    WHERE cs_item_sk IN (SELECT ws_item_sk FROM web_sales)
),
AggregatedSales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        SUM(CASE WHEN c.c_customer_sk IS NOT NULL THEN ws_quantity ELSE 0 END) AS total_web_quantity,
        SUM(CASE WHEN c.c_customer_sk IS NOT NULL THEN ws_net_paid ELSE 0 END) AS total_web_sales,
        COUNT(DISTINCT ws_sold_date_sk) AS web_sales_days,
        SUM(CASE WHEN sr_return_quantity IS NOT NULL THEN sr_return_quantity ELSE 0 END) AS total_returns
    FROM SalesCTE s
    LEFT JOIN item ON s.ws_item_sk = item.i_item_sk
    LEFT JOIN store_returns sr ON s.ws_item_sk = sr.sr_item_sk
    LEFT JOIN customer c ON s.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY item.i_item_id, item.i_product_name
)
SELECT 
    asales.i_item_id,
    asales.i_product_name,
    asales.total_web_quantity,
    asales.total_web_sales,
    asales.web_sales_days,
    asales.total_returns,
    COALESCE(NULLIF(asales.total_web_sales, 0), 1) AS safe_sales,  -- Prevent division by zero
    ROUND(asales.total_web_sales / NULLIF(asales.total_web_quantity, 0), 2) AS average_price
FROM AggregatedSales asales
WHERE asales.total_web_sales > 1000
ORDER BY average_price DESC
FETCH FIRST 10 ROWS ONLY;
