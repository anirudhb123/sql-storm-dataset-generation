
WITH RECURSIVE MonthlySales AS (
    SELECT
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        d_year,
        d_month_seq
    FROM web_sales
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY ws_sold_date_sk, d_year, d_month_seq
    UNION ALL
    SELECT
        ws_sold_date_sk,
        total_sales + 
            COALESCE((SELECT SUM(ws_ext_sales_price)
                      FROM web_sales
                      JOIN date_dim ON ws_sold_date_sk = d_date_sk
                      WHERE d_year = m.d_year AND d_month_seq = m.d_month_seq - 1), 0) AS total_sales,
        d_year,
        d_month_seq
    FROM MonthlySales m
    JOIN date_dim d ON m.ws_sold_date_sk = d.d_date_sk
    WHERE m.d_month_seq > 1
),
TopStores AS (
    SELECT 
        s_store_id,
        SUM(ss_ext_sales_price) AS total_store_sales
    FROM store_sales
    JOIN store ON ss_store_sk = s_store_sk
    GROUP BY s_store_id
    ORDER BY total_store_sales DESC
    LIMIT 10
),
CustomerReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    GROUP BY sr_customer_sk
)
SELECT 
    c.c_customer_id,
    COALESCE(c.c_first_name, 'Unknown') AS first_name,
    COALESCE(c.c_last_name, 'Unknown') AS last_name,
    cd.cd_gender,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    (SELECT AVG(total_sales) FROM MonthlySales WHERE d_year = 2023) AS average_monthly_sales,
    (SELECT total_store_sales FROM TopStores WHERE ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_store_sales) = 1) AS top_store_sales,
    (SELECT total_returns FROM CustomerReturns WHERE sr_customer_sk = c.c_customer_sk) AS total_customer_returns
FROM 
    customer c
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender
HAVING 
    total_sales > COALESCE((SELECT AVG(total_sales) FROM MonthlySales), 0)
ORDER BY 
    total_sales DESC
LIMIT 100;
