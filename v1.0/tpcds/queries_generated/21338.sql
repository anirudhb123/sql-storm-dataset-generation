
WITH RankedSales AS (
    SELECT
        cs.customer_sk,
        cs_order_number,
        cs_item_sk,
        ROW_NUMBER() OVER (PARTITION BY cs.customer_sk ORDER BY cs_sold_date_sk DESC) AS rn,
        cs_net_profit,
        CASE 
            WHEN cs_sales_price IS NULL THEN 0 
            ELSE cs_sales_price 
        END AS adjusted_sales_price,
        COALESCE((
            SELECT SUM(ws_ext_sales_price) 
            FROM web_sales 
            WHERE ws_bill_customer_sk = cs.customer_sk 
            AND ws_sold_date_sk >= cs_sold_date_sk
        ), 0) AS web_total_sales
    FROM
        catalog_sales cs
    WHERE
        cs_sold_date_sk >= ((SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 100)
    ORDER BY cs.customer_sk
),
FilteredReturns AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_quantity) AS total_returned
    FROM 
        store_returns 
    WHERE 
        sr_returned_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY sr_returning_customer_sk
)
SELECT 
    customer.c_customer_id,
    c_first_name || ' ' || c_last_name AS full_name,
    COALESCE(sales.rn, 0) AS sales_rank,
    COALESCE(sales.cs_net_profit, 0) AS net_profit,
    COALESCE(sales.adjusted_sales_price, 0) AS last_order_sales_price,
    COALESCE(returns.total_returned, 0) AS total_returns,
    CASE 
        WHEN COALESCE(sales.web_total_sales, 0) = 0 THEN 'No web sales'
        WHEN returns.total_returned IS NOT NULL THEN 'Has returns'
        ELSE 'No returns' 
    END AS return_status
FROM 
    customer
LEFT JOIN 
    RankedSales sales ON customer.c_customer_sk = sales.customer_sk
LEFT JOIN 
    FilteredReturns returns ON customer.c_customer_sk = returns.sr_returning_customer_sk
WHERE 
    customer.c_current_cdemo_sk IS NOT NULL 
    AND customer.c_birth_year IS NOT NULL 
    AND (customer.c_first_name ILIKE '%a%' OR customer.c_last_name ILIKE '%a%')
ORDER BY 
    sales_rank ASC, 
    net_profit DESC
FETCH FIRST 100 ROWS ONLY;
