
WITH RECURSIVE DateHierarchy AS (
    SELECT d_date_sk, d_date, d_year, d_month_seq, d_week_seq
    FROM date_dim
    WHERE d_year = 2023
    UNION ALL
    SELECT d.d_date_sk, d.d_date, d.d_year, d.d_month_seq, d.d_week_seq
    FROM date_dim d
    JOIN DateHierarchy dh ON d.d_date_sk = dh.d_date_sk + 1
),
SalesAnalysis AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_profit,
        COALESCE(SUM(cs.cs_net_profit), 0) AS total_catalog_profit,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_store_profit,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
),
RankedSales AS (
    SELECT 
        c.c_customer_sk,
        sa.total_web_profit,
        sa.total_catalog_profit,
        sa.total_store_profit,
        RANK() OVER (PARTITION BY (CASE
            WHEN sa.total_web_profit > sa.total_catalog_profit AND sa.total_web_profit > sa.total_store_profit THEN 'Web'
            WHEN sa.total_catalog_profit > sa.total_web_profit AND sa.total_catalog_profit > sa.total_store_profit THEN 'Catalog'
            ELSE 'Store'
        END) ORDER BY sa.total_web_profit DESC, sa.total_catalog_profit DESC, sa.total_store_profit DESC) AS sales_rank
    FROM SalesAnalysis sa
    JOIN customer c ON sa.c_customer_sk = c.c_customer_sk
)
SELECT 
    c.c_customer_sk,
    CASE 
        WHEN r.total_web_profit > 0 THEN 'Online'
        WHEN r.total_catalog_profit > 0 THEN 'Catalog'
        ELSE 'In-Store'
    END AS purchase_channel,
    r.total_web_profit,
    r.total_catalog_profit,
    r.total_store_profit,
    r.sales_rank
FROM RankedSales r
JOIN customer c ON r.c_customer_sk = c.c_customer_sk
WHERE r.sales_rank <= 10
  AND EXISTS (
      SELECT 1
      FROM customer_address ca
      WHERE ca.ca_address_sk = c.c_current_addr_sk
      AND ca.ca_state = 'CA'
  )
ORDER BY purchase_channel, r.sales_rank;
