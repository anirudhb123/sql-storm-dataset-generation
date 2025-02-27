
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_sales_price DESC) AS sales_rank,
        SUM(ws_sales_price) OVER (PARTITION BY ws.web_site_sk) AS total_sales_per_site,
        CASE 
            WHEN ws_sales_price > 100 THEN 'High Value'
            WHEN ws_sales_price BETWEEN 50 AND 100 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS sale_category
    FROM web_sales ws
    INNER JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
),
FilteredSales AS (
    SELECT 
        web_site_sk,
        ws_order_number,
        sales_rank,
        total_sales_per_site,
        sale_category
    FROM RankedSales 
    WHERE sales_rank <= 10
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk, 
        SUM(CASE WHEN sr_return_quantity IS NULL THEN 0 ELSE sr_return_quantity END) AS total_returns
    FROM store_returns 
    GROUP BY sr_customer_sk
)
SELECT 
    fs.web_site_sk,
    fs.ws_order_number,
    fs.sale_category,
    fs.total_sales_per_site,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COUNT(DISTINCT cr.sr_customer_sk) AS unique_customers_returned
FROM FilteredSales fs
LEFT JOIN CustomerReturns cr ON fs.web_site_sk = cr.sr_customer_sk
GROUP BY 
    fs.web_site_sk, 
    fs.ws_order_number, 
    fs.sale_category, 
    fs.total_sales_per_site
HAVING 
    COALESCE(cr.total_returns, 0) > 0 OR MAX(fs.total_sales_per_site) > 500
ORDER BY fs.web_site_sk, total_sales_per_site DESC
LIMIT 50;
