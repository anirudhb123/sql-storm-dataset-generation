
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_ext_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 2451610 AND 2451640
),
TopWebSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM
        RankedSales
    WHERE
        rank <= 5
    GROUP BY
        ws_item_sk
),
StoreSalesWithPromotions AS (
    SELECT
        ss_item_sk,
        ss_net_profit,
        p.p_discount_active,
        p.p_promo_name
    FROM
        store_sales ss
    LEFT JOIN
        promotion p ON ss.promo_sk = p.p_promo_sk
    WHERE
        ss_sold_date_sk IN (SELECT DISTINCT sr_returned_date_sk FROM store_returns)
),
AggregatedSales AS (
    SELECT
        s.ss_item_sk,
        COALESCE(tws.total_sales, 0) AS total_web_sales,
        SUM(s.net_profit) AS total_store_profit
    FROM
        StoreSalesWithPromotions s
    LEFT JOIN
        TopWebSales tws ON s.ss_item_sk = tws.ws_item_sk
    GROUP BY
        s.ss_item_sk
)
SELECT
    a.ss_item_sk,
    a.total_web_sales,
    a.total_store_profit,
    CASE
        WHEN a.total_web_sales > 0 AND a.total_store_profit > 0 THEN 'Both Profitable'
        WHEN a.total_web_sales > 0 AND a.total_store_profit = 0 THEN 'Web Only Profitable'
        WHEN a.total_web_sales = 0 AND a.total_store_profit > 0 THEN 'Store Only Profitable'
        ELSE 'Neither Profitable'
    END AS profitability_status,
    SUM(NULLIF(a.total_store_profit, 0)) FILTER (WHERE p.p_discount_active = 'Y') AS active_discounted_profits
FROM
    AggregatedSales a
LEFT JOIN
    promotion p ON a.ss_item_sk = p.p_promo_sk
GROUP BY
    a.ss_item_sk, a.total_web_sales, a.total_store_profit
HAVING
    (total_web_sales + total_store_profit) > 0
ORDER BY
    profitability_status DESC, total_web_sales DESC;
