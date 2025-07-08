
WITH RECURSIVE sales_data AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        SUM(ws_ext_sales_price) AS total_sales,
        FIRST_VALUE(ws_sold_date_sk) OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS first_sale_date
    FROM
        web_sales
    GROUP BY
        ws_item_sk, ws_order_number
),
total_sales_by_item AS (
    SELECT
        item.i_item_sk,
        item.i_item_id,
        COALESCE(SUM(sd.total_sales), 0) AS total_sales,
        COUNT(sd.ws_order_number) AS order_count,
        MIN(sd.first_sale_date) AS first_sale_date
    FROM
        item
    LEFT JOIN sales_data sd ON item.i_item_sk = sd.ws_item_sk
    GROUP BY
        item.i_item_sk, item.i_item_id
),
customer_sales AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_purchases,
        SUM(ss.ss_ext_sales_price) AS total_store_spent,
        AVG(ss.ss_net_profit) AS avg_profit_per_purchase
    FROM
        customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY
        c.c_customer_sk
)
SELECT
    cs.c_customer_sk,
    cs.total_store_purchases,
    cs.total_store_spent,
    cs.avg_profit_per_purchase,
    tsbi.total_sales,
    tsbi.order_count,
    tsbi.first_sale_date
FROM
    customer_sales cs
FULL OUTER JOIN total_sales_by_item tsbi ON cs.c_customer_sk = tsbi.i_item_sk
WHERE
    (cs.total_store_purchases > 1 OR tsbi.total_sales > 1000)
    AND (cs.total_store_spent IS NOT NULL OR tsbi.total_sales IS NOT NULL)
ORDER BY
    cs.total_store_purchases DESC,
    tsbi.total_sales DESC
LIMIT 100;
