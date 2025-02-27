
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rnk
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) - 30
),
StoreSalesSummary AS (
    SELECT 
        ss.s_store_sk,
        SUM(ss.ss_net_paid) AS total_net_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY ss.s_store_sk
),
CommonReturns AS (
    SELECT 
        cr.cr_returning_customer_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS total_returns
    FROM catalog_returns cr
    GROUP BY cr.cr_returning_customer_sk
)
SELECT 
    s.s_store_name,
    COALESCE(rs.total_net_sales, 0) AS total_net_sales,
    COALESCE(rs.total_transactions, 0) AS total_transactions,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    SUM(rs.ws_sales_price) OVER (PARTITION BY s.s_store_sk) AS total_sales_price_per_store,
    COUNT(DISTINCT rs.ws_item_sk) AS unique_items_sold
FROM store s
LEFT JOIN StoreSalesSummary rs ON s.s_store_sk = rs.s_store_sk
LEFT JOIN CommonReturns cr ON cr.cr_returning_customer_sk IN (
    SELECT c.c_customer_sk 
    FROM customer c 
    WHERE c.c_current_hdemo_sk = rs.rnk
)
WHERE s.s_state = 'CA'
GROUP BY s.s_store_name
ORDER BY total_net_sales DESC;
