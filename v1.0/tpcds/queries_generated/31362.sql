
WITH RECURSIVE sales_hierarchy AS (
    SELECT
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions,
        1 AS level
    FROM
        store_sales
    WHERE
        ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    GROUP BY
        ss_store_sk

    UNION ALL

    SELECT
        ss.store_sk AS ss_store_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions,
        sh.level + 1 AS level
    FROM
        sales_hierarchy sh
    JOIN store_sales ss ON sh.ss_store_sk = ss.ss_store_sk
    WHERE
        ss.ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    GROUP BY
        ss.store_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    a.ca_city,
    a.ca_state,
    SUM(ws.ws_sales_price) AS total_web_sales,
    RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank,
    CASE
        WHEN hd.hd_buy_potential IS NULL THEN 'Unknown'
        ELSE hd.hd_buy_potential
    END AS buy_potential
FROM
    customer c
LEFT JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE
    ws.ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    AND a.ca_state IS NOT NULL
GROUP BY
    c.c_customer_id, c.c_first_name, c.c_last_name, a.ca_city, a.ca_state, hd.hd_buy_potential
HAVING 
    SUM(ws.ws_sales_price) > (SELECT AVG(ws2.ws_sales_price) FROM web_sales ws2 WHERE ws2.ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales))
ORDER BY 
    total_web_sales DESC
LIMIT 10;
