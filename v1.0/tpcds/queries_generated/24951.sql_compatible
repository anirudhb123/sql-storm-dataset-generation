
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
customer_return_data AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(DISTINCT wr_return_number) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount,
        DENSE_RANK() OVER (ORDER BY SUM(wr_return_amt) DESC) AS return_rank
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
combined_sales_returns AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        cr.total_returns,
        COALESCE(cr.total_return_amount, 0) AS return_amount,
        COALESCE(cs.total_sales - cr.total_return_amount, cs.total_sales) AS net_sales
    FROM 
        customer c
    LEFT JOIN 
        ranked_sales cs ON c.c_customer_sk = cs.ws_item_sk
    LEFT JOIN 
        customer_return_data cr ON c.c_customer_sk = cr.wr_returning_customer_sk
    WHERE 
        COALESCE(cs.total_sales, 0) > 0
        AND (cr.total_returns > 0 OR cr.total_returns IS NULL)
),
final_analysis AS (
    SELECT 
        c_customer_id,
        total_sales,
        total_returns,
        return_amount,
        net_sales,
        CASE 
            WHEN net_sales IS NULL THEN 'No Sales'
            WHEN net_sales < 0 THEN 'Net Loss'
            ELSE 'Profitable'
        END AS profitability_status
    FROM 
        combined_sales_returns
)
SELECT 
    f.c_customer_id,
    f.total_sales,
    f.total_returns,
    f.return_amount,
    f.net_sales,
    f.profitability_status
FROM 
    final_analysis f
WHERE 
    f.profitability_status IS NOT NULL
ORDER BY 
    f.net_sales DESC;
