
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS SalesRank
    FROM web_sales ws
    WHERE ws.ws_sales_price IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_quantity) AS total_returned_quantity,
        SUM(wr.wr_return_amt) AS total_returned_amt,
        COUNT(wr.wr_order_number) AS return_count
    FROM web_returns wr
    GROUP BY wr.wr_returning_customer_sk
),
StoreSalesSummary AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_sales_price) AS total_sales_amt,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk IN (
        SELECT d.d_date_sk 
        FROM date_dim d 
        WHERE d.d_year = 2023 AND d.d_week_seq >= 10 AND d.d_week_seq <= 20
    )
    GROUP BY ss.ss_store_sk
),
TopStores AS (
    SELECT 
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_country,
        s.s_store_sk,
        COALESCE(ss.total_sales_amt, 0) AS total_sales_amt
    FROM store s
    LEFT JOIN StoreSalesSummary ss ON s.s_store_sk = ss.ss_store_sk
    WHERE s.s_state = 'CA'
),
FinalResults AS (
    SELECT 
        cs.c_customer_id,
        COUNT(DISTINCT cs.ss_ticket_number) AS purchase_count,
        MAX(cs.total_return_amt) AS max_return_amt,
        SUM(cs.total_returned_quantity) AS total_quantity_returned,
        SUM(tp.total_sales_amt) AS total_spent,
        CASE 
            WHEN AVG(cs.total_return_amt) IS NULL THEN 'No Returns'
            WHEN AVG(cs.total_return_amt) > 100 THEN 'High Return Rate'
            ELSE 'Normal Return Rate'
        END AS return_category
    FROM TopStores ts
    JOIN CustomerReturns cs ON cs.wr_returning_customer_sk = cs.wr_returning_customer_sk
    LEFT JOIN RankedSales rp ON rp.ws_item_sk = cs.wr_item_sk
    LEFT JOIN web_sales ws ON ws.ws_order_number = rp.ws_order_number
    GROUP BY cs.c_customer_id
)
SELECT 
    fr.c_customer_id,
    fr.purchase_count,
    fr.max_return_amt,
    fr.total_quantity_returned,
    fr.total_spent,
    'Final Summary: ' || 
    CASE 
        WHEN fr.total_quantity_returned > 50 THEN 'Frequent Returner' 
        ELSE 'Occasional Returner' 
    END AS return_summary
FROM FinalResults fr
ORDER BY fr.total_spent DESC, fr.purchase_count DESC
FETCH FIRST 100 ROWS ONLY;
