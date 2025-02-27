
WITH RECURSIVE category_hierarchy AS (
    SELECT i_item_sk AS item_sk, i_category_id AS category_id, 0 AS level
    FROM item
    UNION ALL
    SELECT ch.item_sk, i_category_id, ch.level + 1
    FROM category_hierarchy ch
    JOIN item i ON ch.category_id = i.category_id
    WHERE ch.level < 3
),
sales_summary AS (
    SELECT 
        COALESCE(ws.ws_sold_date_sk, cs.cs_sold_date_sk, ss.ss_sold_date_sk) AS sold_date,
        CASE 
            WHEN ws.ws_sold_date_sk IS NOT NULL THEN 'web' 
            WHEN cs.cs_sold_date_sk IS NOT NULL THEN 'catalog' 
            ELSE 'store' 
        END AS sales_channel,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_sales,
        COUNT(*) AS total_transactions
    FROM web_sales ws
    FULL OUTER JOIN catalog_sales cs ON ws.ws_order_number = cs.cs_order_number
    FULL OUTER JOIN store_sales ss ON ws.ws_order_number = ss.ss_ticket_number
    GROUP BY 1, 2
),
income_distribution AS (
    SELECT 
        hd.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS average_purchase_estimate
    FROM household_demographics hd
    JOIN customer_demographics cd ON hd.hd_demo_sk = cd.cd_demo_sk
    JOIN customer c ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY hd.hd_income_band_sk
),
top_categories AS (
    SELECT 
        category_id, 
        SUM(total_sales) AS total_sales
    FROM sales_summary
    JOIN category_hierarchy ch ON ch.item_sk = ss.ss_item_sk
    GROUP BY category_id
    ORDER BY total_sales DESC
    LIMIT 5
)
SELECT 
    ts.sold_date,
    ts.sales_channel,
    ts.total_sales,
    ts.total_transactions,
    ic.income_band_sk,
    ic.customer_count,
    ic.average_purchase_estimate,
    tc.total_sales AS top_category_sales
FROM sales_summary ts
JOIN income_distribution ic ON ts.sold_date = ic.hd_income_band_sk
LEFT JOIN top_categories tc ON ts.sold_date = tc.category_id
WHERE ts.total_sales > (SELECT AVG(total_sales) FROM sales_summary)
AND (ic.customer_count IS NULL OR ic.customer_count > 50)
ORDER BY ts.sold_date DESC;
