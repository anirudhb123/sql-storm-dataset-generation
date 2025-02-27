
WITH Customer_Returns AS (
    SELECT 
        sr_store_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_tax) AS total_return_tax
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
),
Sales_Data AS (
    SELECT 
        ss_store_sk,
        SUM(ss_quantity) AS total_sales,
        SUM(ss_ext_sales_price) AS total_sales_amount,
        SUM(ss_ext_tax) AS total_sales_tax
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
),
Returns_Sales_Comparison AS (
    SELECT 
        sd.ss_store_sk,
        sd.total_sales,
        sd.total_sales_amount,
        sd.total_sales_tax,
        cr.total_returns,
        cr.return_count,
        cr.total_return_amount,
        cr.total_return_tax
    FROM 
        Sales_Data sd
    LEFT JOIN 
        Customer_Returns cr ON sd.ss_store_sk = cr.sr_store_sk
)
SELECT 
    rsc.ss_store_sk,
    COALESCE(rsc.total_sales, 0) AS total_sales,
    COALESCE(rsc.total_sales_amount, 0) AS total_sales_amount,
    COALESCE(rsc.total_sales_tax, 0) AS total_sales_tax,
    COALESCE(rsc.total_returns, 0) AS total_returns,
    COALESCE(rsc.return_count, 0) AS return_count,
    COALESCE(rsc.total_return_amount, 0) AS total_return_amount,
    COALESCE(rsc.total_return_tax, 0) AS total_return_tax,
    (COALESCE(rsc.total_returns, 0)::NUMERIC / NULLIF(COALESCE(rsc.total_sales, 0), 0)::NUMERIC) * 100 AS return_rate
FROM 
    Returns_Sales_Comparison rsc
ORDER BY 
    rsc.ss_store_sk;
