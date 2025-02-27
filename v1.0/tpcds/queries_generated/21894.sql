
WITH RecursiveSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
CustomerReturns AS (
    SELECT
        wr.returned_date_sk,
        wr.returning_customer_sk,
        COUNT(DISTINCT wr_item_sk) AS return_count,
        SUM(wr_return_amt) AS total_return_amt
    FROM web_returns wr
    WHERE wr.return_quantity > 0
    GROUP BY wr.returned_date_sk, wr.returning_customer_sk
),
StoreSalesSummary AS (
    SELECT
        ss_store_sk,
        SUM(ss_sales_price) AS total_store_sales,
        AVG(ss_net_profit) AS avg_net_profit
    FROM store_sales
    WHERE ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_current_year = 'Y')
    GROUP BY ss_store_sk
)
SELECT 
    ca.city,
    ca.state,
    cs.total_sales,
    cr.total_return_amt,
    COALESCE(cs.total_sales, 0) - COALESCE(cr.total_return_amt,0) AS net_sales,
    ss.total_store_sales,
    ss.avg_net_profit
FROM customer_address ca
LEFT JOIN RecursiveSales cs ON cs.ws_item_sk IN (
    SELECT ws_item_sk 
    FROM web_sales 
    WHERE ws_bill_addr_sk = ca.ca_address_sk
)
LEFT JOIN CustomerReturns cr ON cr.returning_customer_sk = (SELECT c_customer_sk FROM customer WHERE c_current_addr_sk = ca.ca_address_sk)
LEFT JOIN StoreSalesSummary ss ON ss.ss_store_sk = (SELECT s_store_sk FROM store WHERE s_city = ca.city AND s_state = ca.state)
WHERE 
    ca.city IS NOT NULL 
    AND ca.state IS NOT NULL 
    AND (cs.total_sales IS NULL OR cs.total_sales < 10) 
    OR (cr.total_return_amt IS NOT NULL AND cr.total_return_amt > 100)
ORDER BY net_sales DESC, ss.total_store_sales ASC;
