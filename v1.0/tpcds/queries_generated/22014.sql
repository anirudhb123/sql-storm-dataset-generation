
WITH ranked_sales AS (
    SELECT 
        cs_ship_date_sk,
        cs_item_sk,
        cs_sales_price,
        RANK() OVER (PARTITION BY cs_item_sk ORDER BY cs_sales_price DESC) AS rank_sales,
        CUME_DIST() OVER (PARTITION BY cs_item_sk ORDER BY cs_sales_price DESC) AS cume_dist_sales
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
    AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
customer_summary AS (
    SELECT 
        c.c_customer_sk, 
        COUNT(DISTINCT ws_order_number) AS total_orders,
        COUNT(DISTINCT cs_order_number) AS total_catalog_orders,
        SUM(ws_net_profit) AS total_profit,
        SUM(COALESCE(ws_net_paid, 0)) AS total_net_paid,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer AS c
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales AS cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk
),
item_summary AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        SUM(ws.net_paid_inc_tax) AS total_net_paid,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM item AS i
    LEFT JOIN web_sales AS ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_desc
),
combined_summary AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_catalog_orders,
        cs.total_profit,
        cs.total_net_paid,
        is.item_sk,
        is.total_net_paid AS item_total_net_paid,
        is.order_count,
        is.total_sales,
        is.avg_net_profit
    FROM customer_summary cs
    FULL OUTER JOIN item_summary is ON cs.c_customer_sk IS NOT NULL OR is.i_item_sk IS NOT NULL
)

SELECT 
    cs.c_customer_sk,
    COALESCE(cs.total_orders, 0) AS total_orders,
    COALESCE(cs.total_catalog_orders, 0) AS total_catalog_orders,
    cs.total_profit,
    cs.total_net_paid,
    is.item_sk,
    is.item_total_net_paid,
    is.order_count,
    is.total_sales,
    is.avg_net_profit
FROM combined_summary cs
FULL OUTER JOIN (
    SELECT 
        r.cs_item_sk,
        r.rank_sales,
        r.cume_dist_sales
    FROM ranked_sales r
    WHERE r.rank_sales = 1
) AS ranked ON cs.item_sk = ranked.cs_item_sk
WHERE cs.total_profit IS NOT NULL OR is.order_count IS NOT NULL
ORDER BY cs.total_profit DESC NULLS LAST, is.total_sales DESC NULLS LAST;
