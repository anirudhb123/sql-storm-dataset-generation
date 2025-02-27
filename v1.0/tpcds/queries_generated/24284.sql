
WITH RankedSales AS (
    SELECT
        ws_bill_customer_sk,
        COUNT(*) AS sales_count,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
CustomerReturns AS (
    SELECT
        cr_returning_customer_sk,
        SUM(CASE WHEN cr_return_quantity IS NOT NULL THEN cr_return_quantity ELSE 0 END) AS total_returns,
        SUM(cr_return_amt) AS total_return_amount
    FROM
        catalog_returns
    GROUP BY
        cr_returning_customer_sk
),
SalesReturns AS (
    SELECT
        s.ws_bill_customer_sk,
        s.total_profit,
        r.total_returns,
        r.total_return_amount,
        CASE 
            WHEN r.total_returns IS NULL THEN 'No Returns'
            WHEN r.total_returns > s.sales_count THEN 'Excess Returns'
            ELSE 'Normal Returns' 
        END AS return_category
    FROM
        RankedSales s
    LEFT JOIN CustomerReturns r ON s.ws_bill_customer_sk = r.cr_returning_customer_sk
)
SELECT
    c.c_customer_id,
    COALESCE(sr.sales_count, 0) AS sales_count,
    COALESCE(sr.total_profit, 0) AS total_profit,
    COALESCE(sr.total_returns, 0) AS total_returns,
    COALESCE(sr.total_return_amount, 0) AS total_return_amount,
    sr.return_category,
    d.d_year,
    RANK() OVER (PARTITION BY sr.return_category ORDER BY COALESCE(sr.total_profit, 0) DESC) AS category_rank
FROM
    sales_returns sr
JOIN
    customer c ON sr.ws_bill_customer_sk = c.c_customer_sk
JOIN
    date_dim d ON d.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date <= CURRENT_DATE)
WHERE
    (COALESCE(sr.total_profit, 0) > 1000 OR sr.return_category = 'Excess Returns')
    AND (c.c_birth_year IS NULL OR c.c_birth_year BETWEEN 1980 AND 2000)
ORDER BY
    return_category, category_rank
LIMIT 100;
