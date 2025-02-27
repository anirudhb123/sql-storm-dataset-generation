
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        0 AS level
    FROM customer c
    WHERE c.c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        ch.c_birth_year,
        ch.level + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON ch.c_customer_sk = c.c_current_hdemo_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
    GROUP BY ws.ws_item_sk
),
ReturnData AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_value
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk BETWEEN (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022) 
                                         AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
    GROUP BY sr.sr_item_sk
)
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    c.c_birth_year,
    COALESCE(sd.total_quantity, 0) AS total_web_sales_quantity,
    COALESCE(sd.total_sales, 0) AS total_web_sales_value,
    COALESCE(rd.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(rd.total_return_value, 0) AS total_return_value
FROM customer c
LEFT JOIN SalesData sd ON c.c_customer_sk = sd.ws_item_sk
LEFT JOIN ReturnData rd ON sd.ws_item_sk = rd.sr_item_sk
JOIN CustomerHierarchy ch ON c.c_customer_sk = ch.c_customer_sk
WHERE c.c_current_cdemo_sk IN (
    SELECT cd.cd_demo_sk 
    FROM customer_demographics cd 
    WHERE cd.cd_marital_status = 'M' AND cd.cd_gender = 'F'
)
ORDER BY ch.level, c.c_birth_year DESC;
