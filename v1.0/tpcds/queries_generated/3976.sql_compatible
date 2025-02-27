
WITH sales_data AS (
    SELECT 
        wr.order_number AS web_order_number,
        cs.order_number AS catalog_order_number,
        ss.order_number AS store_order_number,
        COALESCE(wr.return_amt, 0) AS web_return_amt,
        COALESCE(cr.return_amount, 0) AS catalog_return_amt,
        COALESCE(sr.return_amt, 0) AS store_return_amt,
        (ws.net_profit + cs.net_profit + ss.net_profit) AS total_profit,
        (ws.net_paid + cs.net_paid + ss.net_paid) AS total_sales
    FROM
        web_sales ws
    FULL OUTER JOIN web_returns wr ON ws.order_number = wr.order_number
    FULL OUTER JOIN catalog_sales cs ON ws.order_number = cs.order_number
    FULL OUTER JOIN catalog_returns cr ON cs.order_number = cr.order_number
    FULL OUTER JOIN store_sales ss ON ws.order_number = ss.order_number
    FULL OUTER JOIN store_returns sr ON ss.order_number = sr.order_number
),
profit_analysis AS (
    SELECT
        web_order_number,
        catalog_order_number,
        store_order_number,
        total_profit,
        total_sales,
        ROW_NUMBER() OVER (PARTITION BY total_profit ORDER BY total_sales DESC) AS profit_rank
    FROM sales_data
    WHERE (total_profit IS NOT NULL AND total_profit > 0) 
      OR (total_sales IS NOT NULL AND total_sales > 0)
)
SELECT
    COALESCE(web_order_number, catalog_order_number, store_order_number) AS order_number,
    total_profit,
    total_sales,
    profit_rank
FROM profit_analysis
WHERE profit_rank <= 10
ORDER BY total_profit DESC, total_sales DESC;
