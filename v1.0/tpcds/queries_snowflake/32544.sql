
WITH RECURSIVE SalesHierarchy AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        NULL AS parent_customer_sk
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
    UNION ALL
    SELECT
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        sh.c_customer_sk AS parent_customer_sk
    FROM
        customer ch
    JOIN SalesHierarchy sh ON sh.c_customer_sk = ch.c_current_cdemo_sk
    LEFT JOIN web_sales ws ON ch.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY
        ch.c_customer_sk, ch.c_first_name, ch.c_last_name, sh.c_customer_sk
),
SalesWithAddress AS (
    SELECT
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.total_sales,
        sh.total_profit,
        ca.ca_city,
        ca.ca_state,
        RANK() OVER (PARTITION BY ca.ca_city ORDER BY sh.total_sales DESC) AS sales_rank
    FROM
        SalesHierarchy sh
    LEFT JOIN customer_address ca ON ca.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = sh.c_customer_sk)
)
SELECT 
    s.c_customer_sk,
    s.c_first_name,
    s.c_last_name,
    COALESCE(s.total_sales, 0) AS sales_amount,
    COALESCE(s.total_profit, 0) AS profit_amount,
    COALESCE(s.ca_city, 'Unknown') AS city,
    COALESCE(s.ca_state, 'Unknown') AS state,
    CASE 
        WHEN s.sales_rank IS NULL THEN 'No sales'
        ELSE CONCAT('Rank ', CAST(s.sales_rank AS VARCHAR))
    END AS sales_description
FROM
    SalesWithAddress s
LEFT JOIN customer_demographics cd ON s.c_customer_sk = cd.cd_demo_sk
WHERE
    (cd.cd_gender IS NULL OR cd.cd_gender = 'M')
    AND (cd.cd_marital_status IS NOT NULL OR cd.cd_purchase_estimate > 500)
ORDER BY 
    s.total_sales DESC
LIMIT 100;
