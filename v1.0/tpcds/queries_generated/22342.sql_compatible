
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        MAX(ws.ws_sold_date_sk) AS last_sold_date
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        c.c_birth_year >= 1970
        AND cd.cd_marital_status IN ('M', 'S')
    GROUP BY
        ws.ws_item_sk, ws.ws_order_number
),
TopItems AS (
    SELECT
        ris.ws_item_sk,
        ris.total_quantity,
        ris.total_sales,
        ris.last_sold_date
    FROM
        RankedSales ris
    WHERE
        ris.rank <= 5
)
SELECT
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_sales,
    di.d_year,
    di.d_qoy,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    ROUND(AVG(ti.total_sales), 2) AS avg_sales,
    STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS top_customers
FROM
    TopItems ti
JOIN
    date_dim di ON di.d_date_sk = ti.last_sold_date
LEFT JOIN
    web_sales ws ON ws.ws_item_sk = ti.ws_item_sk
LEFT JOIN
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk 
GROUP BY
    ti.ws_item_sk, ti.total_quantity, ti.total_sales, di.d_year, di.d_qoy
ORDER BY
    ti.total_sales DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
UNION ALL
SELECT
    NULL AS ws_item_sk,
    NULL AS total_quantity,
    NULL AS total_sales,
    NULL AS d_year,
    NULL AS d_qoy,
    NULL AS order_count,
    NULL AS avg_sales,
    'Total Count' AS top_customers
FROM
    (SELECT COUNT(*) FROM web_sales) AS total_sales_count
WHERE
    (SELECT COUNT(*) FROM web_sales) > 0
