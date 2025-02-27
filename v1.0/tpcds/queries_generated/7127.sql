
WITH RankedSales AS (
    SELECT
        ws_web_site_sk,
        ws_sold_date_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_web_site_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws_web_site_sk,
        ws_sold_date_sk
),
TopWebsites AS (
    SELECT
        ws_web_site_sk,
        total_profit,
        order_count
    FROM
        RankedSales
    WHERE
        profit_rank <= 10
),
CustomerSales AS (
    SELECT
        c_customer_sk,
        c.first_name,
        c.last_name,
        SUM(ws_ext_sales_price) AS total_spent
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        TopWebsites tw ON ws.ws_web_site_sk = tw.ws_web_site_sk
    GROUP BY
        c_customer_sk, c.first_name, c.last_name
)
SELECT
    cs.first_name,
    cs.last_name,
    cs.total_spent,
    tw.total_profit AS website_profit,
    tw.order_count AS order_total
FROM
    CustomerSales cs
JOIN 
    TopWebsites tw ON cs.c_customer_sk = (
        SELECT ws_bill_customer_sk 
        FROM web_sales 
        WHERE ws_web_site_sk = tw.ws_web_site_sk
        ORDER BY ws_ext_sales_price DESC
        LIMIT 1
    )
ORDER BY
    cs.total_spent DESC
LIMIT 20;
