
WITH RECURSIVE sales_hierarchy AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ss.ss_item_sk,
        ss.ss_net_paid,
        1 AS level
    FROM
        customer c
    JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE
        ss.ss_sold_date_sk = (
            SELECT MAX(ss_inner.ss_sold_date_sk)
            FROM store_sales ss_inner
            WHERE ss_inner.ss_customer_sk = c.c_customer_sk
        )
    UNION ALL
    SELECT
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        ss.ss_item_sk,
        ss.ss_net_paid,
        sh.level + 1
    FROM
        sales_hierarchy sh
    JOIN
        store_sales ss ON sh.ss_item_sk = ss.ss_item_sk
    WHERE
        ss.ss_sold_date_sk < (
            SELECT MIN(ss_inner.ss_sold_date_sk)
            FROM store_sales ss_inner
            WHERE ss_inner.ss_customer_sk = sh.c_customer_sk AND ss_inner.ss_sold_date_sk > 
            (SELECT MAX(ss_inner1.ss_sold_date_sk)
             FROM store_sales ss_inner1
             WHERE ss_inner1.ss_customer_sk = sh.c_customer_sk)
        )
),
customer_category AS (
    SELECT
        cd.cd_demo_sk,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count
    FROM
        customer_demographics cd
    JOIN
        store_sales ss ON ss.ss_customer_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_demo_sk
    HAVING
        SUM(ss.ss_net_paid) > 1000
),
 ranked_customers AS (
    SELECT
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        SUM(ch.ss_net_paid) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(ch.ss_net_paid) DESC) AS rank
    FROM
        sales_hierarchy ch
    GROUP BY
        ch.c_customer_sk, ch.c_first_name, ch.c_last_name
)
SELECT
    r.rank,
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    COALESCE(cc.total_spent, 0) AS total_spent,
    r.total_sales
FROM
    ranked_customers r
LEFT JOIN
    customer_category cc ON r.c_customer_sk = cc.cd_demo_sk
WHERE
    r.rank <= 10
ORDER BY
    r.rank
LIMIT 10;
