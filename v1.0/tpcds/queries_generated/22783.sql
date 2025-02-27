
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
HighPerformingItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_sales,
        CASE 
            WHEN rs.total_sales IS NULL THEN 'No Sales'
            WHEN rs.total_sales > 1000 THEN 'High Value Item'
            ELSE 'Standard Item'
        END AS item_category
    FROM 
        RankedSales rs 
    WHERE 
        rs.sales_rank <= 10
),
TotalReturns AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    hi.ws_item_sk,
    hi.total_sales,
    COALESCE(tr.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(tr.total_return_amount, 0) AS total_return_amount,
    hi.item_category,
    CASE 
        WHEN hi.total_sales IS NOT NULL AND (COALESCE(tr.total_return_amount, 0) > hi.total_sales) 
            THEN 'WARNING: High Return Rate'
        ELSE 'Return Rate Acceptable'
    END AS return_analysis
FROM 
    HighPerformingItems hi
LEFT JOIN 
    TotalReturns tr ON hi.ws_item_sk = tr.cr_item_sk
WHERE 
    hi.item_category = 'High Value Item'
ORDER BY 
    hi.total_sales DESC;

WITH concat_info AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS order_date,
        ws.ws_sales_price,
        ws.ws_net_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND 
        ws.ws_net_profit IS NOT NULL
)
SELECT
    full_name,
    order_date,
    ROW_NUMBER() OVER (PARTITION BY DATEPART(MONTH, order_date) ORDER BY ws_net_profit DESC) AS rank_within_month,
    SUM(ws_net_profit) OVER (PARTITION BY full_name ORDER BY order_date) AS cumulative_profit
FROM 
    concat_info
WHERE 
    rank_within_month <= 3;
