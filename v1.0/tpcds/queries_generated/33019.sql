
WITH RECURSIVE SalesCTE AS (
    SELECT
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_net_profit
    FROM
        store_sales
    GROUP BY
        ss_item_sk

    UNION ALL

    SELECT
        ss_item_sk,
        SUM(ss_quantity) + (SELECT IFNULL(SUM(ws_quantity), 0) FROM web_sales WHERE ws_item_sk = ss.item_sk) AS total_quantity,
        SUM(ss_net_profit) + (SELECT IFNULL(SUM(ws_net_profit), 0) FROM web_sales WHERE ws_item_sk = ss.item_sk) AS total_net_profit
    FROM
        store_sales ss
    INNER JOIN SalesCTE scte ON ss.ss_item_sk = scte.ss_item_sk
    GROUP BY
        ss_item_sk
),
CustomerStats AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_spent
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),

ItemSales AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        COALESCE(SUM(ss.ss_quantity), 0) AS store_quantity,
        COALESCE(SUM(ws.ws_quantity), 0) AS web_quantity,
        COALESCE(SUM(ss.ss_net_profit), 0) AS store_profit,
        COALESCE(SUM(ws.ws_net_profit), 0) AS web_profit
    FROM
        item i
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY
        i.i_item_sk, i.i_item_id
)

SELECT
    cs.c_customer_sk,
    cs.cd_gender,
    SUM(cs.total_spent) AS customer_total_spent,
    COUNT(DISTINCT cs.total_orders) AS customer_total_orders,
    i.i_item_id,
    i.store_quantity,
    i.web_quantity,
    i.store_profit,
    i.web_profit
FROM
    CustomerStats cs
JOIN ItemSales i ON cs.c_customer_sk = i.i_item_sk
WHERE
    cs.total_spent > 100 AND (cs.cd_marital_status = 'M' OR cs.cd_gender = 'F')
GROUP BY
    cs.c_customer_sk, cs.cd_gender, i.i_item_id, i.store_quantity, i.web_quantity, i.store_profit, i.web_profit
ORDER BY
    customer_total_spent DESC,
    cs.c_customer_sk
LIMIT 50;
