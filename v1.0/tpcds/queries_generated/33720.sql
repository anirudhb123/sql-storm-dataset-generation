
WITH RECURSIVE SalesSummary AS (
    SELECT
        s_store_sk,
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(ss_ticket_number) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY SUM(ss_net_profit) DESC) AS sales_rank
    FROM store_sales
    WHERE ss_sold_date_sk >= (SELECT MAX(d_date_sk) - INTERVAL '1 YEAR' FROM date_dim)
    GROUP BY s_store_sk
),
TopStores AS (
    SELECT
        s_store_sk,
        s_store_name,
        total_net_profit,
        total_sales,
        CASE 
            WHEN total_sales > 100 THEN 'High Sales'
            WHEN total_sales BETWEEN 50 AND 100 THEN 'Moderate Sales'
            ELSE 'Low Sales' 
        END AS sales_category
    FROM SalesSummary
    JOIN store ON SalesSummary.s_store_sk = store.s_store_sk
    WHERE sales_rank <= 10
),
CustomerReturns AS (
    SELECT
        sr_store_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    GROUP BY sr_store_sk
),
FinalReport AS (
    SELECT
        ts.s_store_name,
        ts.total_net_profit,
        ts.total_sales,
        ts.sales_category,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        (ts.total_net_profit - COALESCE(cr.total_return_amount, 0)) AS net_profit_after_returns
    FROM TopStores ts
    LEFT JOIN CustomerReturns cr ON ts.s_store_sk = cr.sr_store_sk
)
SELECT
    store_name,
    total_net_profit,
    total_sales,
    sales_category,
    total_returns,
    total_return_amount,
    net_profit_after_returns,
    CONCAT('Store ', store_name, ' has a net profit of ', ROUND(net_profit_after_returns, 2)) AS profit_statement
FROM FinalReport
ORDER BY total_net_profit DESC;
