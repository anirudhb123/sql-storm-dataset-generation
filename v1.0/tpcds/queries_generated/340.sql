
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rank_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim)
), CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
), SalesSummary AS (
    SELECT 
        cs.bill_customer_sk,
        COUNT(cs.order_number) AS total_orders,
        SUM(cs.ext_sales_price) AS total_sales,
        SUM(cs.ext_discount_amt) AS total_discount,
        COALESCE(SUM(cr.return_amt), 0) AS total_returns
    FROM 
        catalog_sales cs
    LEFT JOIN 
        catalog_returns cr ON cs.order_number = cr.order_number
    GROUP BY 
        cs.bill_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ss.total_orders,
    ss.total_sales,
    ss.total_discount,
    ss.total_returns,
    CASE 
        WHEN ss.total_sales > 1000 THEN 'High Value'
        WHEN ss.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value,
    r.total_return_amount,
    r.return_count
FROM 
    customer c
LEFT JOIN 
    SalesSummary ss ON c.c_customer_sk = ss.bill_customer_sk
LEFT JOIN 
    CustomerReturns r ON c.c_customer_sk = r.wr_returning_customer_sk
WHERE 
    c.c_current_cdemo_sk IS NOT NULL
    AND (ss.total_sales > 0 OR r.total_return_amount IS NOT NULL)
ORDER BY 
    ss.total_sales DESC,
    r.return_count DESC
FETCH FIRST 100 ROWS ONLY;
