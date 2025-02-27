
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           cd.cd_marital_status, cd.cd_gender, cd.cd_dep_count,
           0 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           cd.cd_marital_status, cd.cd_gender, cd.cd_dep_count,
           ch.level + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON ch.c_customer_sk = c.c_current_hdemo_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'
), 
SalesMetrics AS (
    SELECT 
        COALESCE(wp.wp_web_page_sk, 0) AS page_sk,
        SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY wp.wp_web_page_sk
),
AbandonedCarts AS (
    SELECT 
        c.c_customer_sk,
        COUNT(wp.wp_web_page_sk) AS abandoned_count
    FROM web_page wp
    INNER JOIN web_sales ws ON wp.wp_web_page_sk = ws.ws_web_page_sk
    LEFT JOIN store_returns sr ON ws.ws_order_number = sr.sr_ticket_number
    LEFT JOIN catalog_returns cr ON ws.ws_order_number = cr.cr_order_number
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE sr.sr_returned_date_sk IS NULL AND cr.cr_returned_date_sk IS NULL AND wr.wr_returned_date_sk IS NULL
    GROUP BY c.c_customer_sk
)
SELECT 
    DISTINCT ch.c_customer_sk,
    ch.c_first_name,
    ch.c_last_name,
    ch.cd_marital_status,
    m.total_sales,
    m.order_count,
    COALESCE(ac.abandoned_count, 0) AS abandoned_carts,
    DENSE_RANK() OVER (PARTITION BY ch.cd_gender ORDER BY m.total_sales DESC) AS sales_rank
FROM CustomerHierarchy ch
LEFT JOIN SalesMetrics m ON ch.c_current_cdemo_sk = m.page_sk
LEFT JOIN AbandonedCarts ac ON ch.c_customer_sk = ac.c_customer_sk
WHERE (m.total_sales > 5000 OR ac.abandoned_count > 3)
ORDER BY ch.cd_gender, sales_rank;
