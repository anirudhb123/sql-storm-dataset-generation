
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.web_site_sk
),
TopSales AS (
    SELECT 
        rs.web_site_sk,
        rs.total_sales
    FROM RankedSales rs
    WHERE rs.sales_rank <= 5
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender
)
SELECT
    ts.web_site_sk,
    cs.cd_gender,
    cs.order_count,
    cs.total_spent,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Purchases'
        WHEN cs.total_spent > 1000 THEN 'High Spender'
        ELSE 'Regular Spender'
    END AS customer_type
FROM TopSales ts
FULL OUTER JOIN CustomerStats cs ON ts.web_site_sk = cs.c_customer_sk
WHERE (cs.order_count > 0 OR cs.order_count IS NULL)
ORDER BY ts.web_site_sk, cs.cd_gender;
