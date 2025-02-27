
WITH RECURSIVE SalesHierarchy AS (
    SELECT
        ss_store_sk,
        SUM(ss_net_profit) AS total_net_profit,
        1 AS level
    FROM
        store_sales
    WHERE
        ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim) - 30
    GROUP BY
        ss_store_sk

    UNION ALL

    SELECT
        sh.ss_store_sk,
        SUM(ss.net_profit) + sh.total_net_profit AS total_net_profit,
        level + 1
    FROM
        store_sales ss
    JOIN
        SalesHierarchy sh ON ss.ss_store_sk = sh.ss_store_sk
    WHERE
        level < 5
    GROUP BY
        sh.ss_store_sk, sh.total_net_profit, level
),
TopStores AS (
    SELECT
        s.s_store_name,
        sh.total_net_profit
    FROM
        SalesHierarchy sh
    JOIN
        store s ON s.s_store_sk = sh.ss_store_sk
    ORDER BY
        sh.total_net_profit DESC
    LIMIT 10
),
PromotionDetails AS (
    SELECT
        p.p_promo_name,
        COUNT(ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    LEFT JOIN
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE
        ws.ws_sales_price > (SELECT AVG(ws_sales_price) FROM web_sales)
    GROUP BY
        p.p_promo_name
),
CustomerEngagement AS (
    SELECT
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_credit_rating IS NOT NULL
    GROUP BY
        cd.cd_gender
)
SELECT
    ts.s_store_name,
    ts.total_net_profit,
    pd.p_promo_name,
    pd.order_count,
    ce.cd_gender,
    ce.customer_count,
    ce.avg_purchase_estimate
FROM
    TopStores ts
FULL OUTER JOIN
    PromotionDetails pd ON ts.s_store_name = pd.p_promo_name
FULL OUTER JOIN
    CustomerEngagement ce ON ce.cd_gender = 'F'
WHERE
    (ts.total_net_profit IS NOT NULL OR pd.order_count IS NOT NULL OR ce.customer_count IS NOT NULL)
ORDER BY
    COALESCE(ts.total_net_profit, 0) DESC,
    COALESCE(pd.order_count, 0) DESC,
    COALESCE(ce.customer_count, 0) DESC;
