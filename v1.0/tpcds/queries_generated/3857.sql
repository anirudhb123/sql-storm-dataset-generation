
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_paid_inc_tax, 0) + COALESCE(cs.cs_net_paid_inc_tax, 0) + COALESCE(ss.ss_net_paid_inc_tax, 0)) AS total_spent,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(COALESCE(ws.ws_net_paid_inc_tax, 0) + COALESCE(cs.cs_net_paid_inc_tax, 0) + COALESCE(ss.ss_net_paid_inc_tax, 0)) DESC) as spending_rank
    FROM customer c
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpenders AS (
    SELECT *
    FROM CustomerSales
    WHERE total_spent > (
        SELECT AVG(total_spent) FROM CustomerSales
    )
),
ItemSales AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        SUM(COALESCE(ws.ws_quantity, 0) + COALESCE(cs.cs_quantity, 0) + COALESCE(ss.ss_quantity, 0)) AS total_quantity_sold
    FROM item i
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    GROUP BY i.i_item_id, i.i_item_desc
    HAVING SUM(COALESCE(ws.ws_quantity, 0) + COALESCE(cs.cs_quantity, 0) + COALESCE(ss.ss_quantity, 0)) > 100
)
SELECT
    hs.c_first_name,
    hs.c_last_name,
    hs.total_spent,
    it.i_item_desc,
    it.total_quantity_sold
FROM HighSpenders hs
JOIN ItemSales it ON hs.c_customer_sk IN (
    SELECT ws.ws_bill_customer_sk FROM web_sales ws
    WHERE ws.ws_item_sk IN (SELECT i.i_item_sk FROM item i)
)
ORDER BY hs.total_spent DESC, it.total_quantity_sold DESC
LIMIT 10;
