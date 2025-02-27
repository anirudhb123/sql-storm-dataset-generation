
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS sales_rank,
        ws.ws_quantity,
        COALESCE(SUM(ws_ext_sales_price) OVER (PARTITION BY ws.web_site_sk), 0) AS total_sales,
        CASE 
            WHEN SUM(ws_ext_sales_price) OVER (PARTITION BY ws.web_site_sk) IS NULL THEN 'No Sales'
            WHEN SUM(ws_ext_sales_price) OVER (PARTITION BY ws.web_site_sk) = 0 THEN 'Zero Sales'
            ELSE 'Sales Present'
        END AS sales_status
    FROM web_sales ws
    LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
      AND c.c_birth_year IS NOT NULL
),
StoreSalesAggregate AS (
    SELECT
        ss.s_store_sk,
        SUM(ss.ss_ext_sales_price) AS store_total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS unique_tickets,
        COUNT(*) AS total_transactions
    FROM store_sales ss
    GROUP BY ss.s_store_sk
    HAVING SUM(ss.ss_ext_sales_price) > 1000
)
SELECT
    r.web_site_sk,
    r.ws_order_number,
    r.ws_sales_price,
    r.sales_rank,
    s.store_total_sales,
    r.sales_status,
    CASE 
        WHEN r.sales_rank = 1 THEN 'Top Sale'
        ELSE 'Regular Sale'
    END AS sale_type
FROM RankedSales r
FULL OUTER JOIN StoreSalesAggregate s ON r.web_site_sk = s.s_store_sk
WHERE (r.sales_status = 'Sales Present' OR s.store_total_sales IS NOT NULL)
  AND (r.ws_sales_price IS NOT NULL OR s.store_total_sales >= 500)
ORDER BY r.web_site_sk, r.sales_rank DESC, s.store_total_sales DESC;
