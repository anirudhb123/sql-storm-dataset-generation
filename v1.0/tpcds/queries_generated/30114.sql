
WITH RECURSIVE sales_hierarchy AS (
    SELECT
        s_store_sk,
        ss_sold_date_sk,
        SUM(ss_net_profit) AS total_net_profit
    FROM
        store_sales
    WHERE
        ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY
        s_store_sk, ss_sold_date_sk
    UNION ALL
    SELECT
        sh.s_store_sk,
        sh.ss_sold_date_sk,
        SUM(ss.net_profit) AS total_net_profit
    FROM
        sales_hierarchy sh
    JOIN
        store_sales ss ON sh.s_store_sk = ss.s_store_sk AND sh.ss_sold_date_sk < ss.ss_sold_date_sk
    GROUP BY
        sh.s_store_sk, sh.ss_sold_date_sk
),
top_customers AS (
    SELECT
        c.c_customer_sk,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_purchase,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        c.c_birth_year > 1980
    GROUP BY
        c.c_customer_sk
    HAVING
        total_purchase > 1000
),
top_items AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        AVG(i.i_current_price) AS average_price
    FROM
        item i
    JOIN
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY
        i.i_item_sk, i.i_item_id
    ORDER BY
        total_quantity_sold DESC
    LIMIT 10
)
SELECT
    s.store_name,
    sh.total_net_profit,
    tc.total_purchase,
    ti.total_quantity_sold,
    ti.average_price
FROM
    (SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city, 
        s.s_state 
    FROM store s) AS s
LEFT JOIN
    sales_hierarchy sh ON s.s_store_sk = sh.s_store_sk
LEFT JOIN
    top_customers tc ON tc.c_customer_sk = (SELECT c_total.c_customer_sk
                                               FROM customer c_total
                                               WHERE c_total.c_current_addr_sk = s.s_store_sk
                                               ORDER BY tc.total_purchase DESC LIMIT 1)
LEFT JOIN
    top_items ti ON ti.i_item_sk = (SELECT item_i.i_item_sk
                                      FROM top_items item_i
                                      ORDER BY item_i.total_quantity_sold DESC LIMIT 1)
WHERE 
    sh.total_net_profit IS NOT NULL AND tc.total_purchase IS NOT NULL;
