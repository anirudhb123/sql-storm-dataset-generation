
WITH RankedSales AS (
    SELECT
        ws.web_site_id,
        ws_order_number,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY ws.net_profit DESC) AS row_num,
        SUM(ws.net_profit) OVER (PARTITION BY ws.web_site_id) AS total_profit
    FROM web_sales ws
    JOIN customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year IS NOT NULL
      AND (c.c_first_name LIKE 'A%' OR c.c_last_name LIKE 'B%')
),
ReturnStats AS (
    SELECT
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returns,
        COUNT(DISTINCT wr_order_number) AS order_count
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
SalesAndReturns AS (
    SELECT
        r.wr_returning_customer_sk,
        COALESCE(s.total_profit, 0) AS total_profit,
        r.total_returns,
        COUNT(s.ws_order_number) AS sales_count,
        SUM(CASE WHEN r.total_returns > 0 THEN s.ws_quantity ELSE 0 END) AS returns_on_sales
    FROM ReturnStats r
    LEFT JOIN RankedSales s ON r.wr_returning_customer_sk = s.web_site_id
    GROUP BY r.wr_returning_customer_sk, r.total_returns
),
FinalMetrics AS (
    SELECT 
        s.web_site_id, 
        s.total_profit, 
        s.sales_count, 
        s.total_returns,
        CASE 
            WHEN s.total_returns = 0 THEN NULL
            ELSE s.total_profit / s.total_returns
        END AS profit_per_return
    FROM SalesAndReturns s
    WHERE s.sales_count > 10
)
SELECT 
    f.web_site_id, 
    f.total_profit, 
    f.sales_count, 
    f.total_returns, 
    ROUND(f.profit_per_return, 2) AS profit_per_return,
    CASE 
        WHEN f.sales_count > 100 THEN 'High Volume'
        WHEN f.total_profit > 10000 THEN 'High Value'
        ELSE 'Regular'
    END AS performance_category
FROM FinalMetrics f
ORDER BY f.total_profit DESC, f.sales_count DESC
LIMIT 10;
