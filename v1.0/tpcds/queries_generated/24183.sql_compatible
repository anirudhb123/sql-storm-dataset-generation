
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM web_sales ws
    WHERE ws.ws_net_profit IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_returns wr
    GROUP BY wr.wr_returning_customer_sk
),
CombinedData AS (
    SELECT 
        c.c_customer_id,
        COALESCE(cs.cs_sales_price, ss.ss_sales_price) AS total_sales_price,
        COALESCE(rs.ws_net_profit, 0) AS web_net_profit,
        COALESCE(cr.total_return_qty, 0) AS total_return_qty,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        CASE 
            WHEN COALESCE(cr.total_return_amt, 0) > 0 THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN RankedSales rs ON c.c_customer_sk = rs.ws_item_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
)
SELECT 
    cd.c_customer_id,
    SUM(cd.total_sales_price) AS total_sales,
    SUM(cd.web_net_profit) AS total_web_profit,
    SUM(cd.total_return_qty) AS total_qty_returned,
    SUM(cd.total_return_amt) AS total_amt_returned,
    cd.return_status,
    COUNT(DISTINCT cd.c_customer_id) OVER (PARTITION BY cd.return_status) AS customers_with_return_status_count
FROM CombinedData cd
WHERE cd.total_sales_price > 1000
GROUP BY cd.c_customer_id, cd.return_status
HAVING SUM(cd.web_net_profit) > 0 OR COUNT(*) > 3
ORDER BY total_sales DESC, total_web_profit DESC;
