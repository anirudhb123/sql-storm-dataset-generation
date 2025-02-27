
WITH SalesData AS (
    SELECT
        s.s_store_name,
        c.c_first_name,
        c.c_last_name,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_sold_date_sk,
        d.d_date
    FROM
        store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN web_sales ws ON ss.ss_item_sk = ws.ws_item_sk AND ss.ss_sold_date_sk = ws.ws_sold_date_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
        AND ws.ws_sales_price > (SELECT AVG(ws_sales_price) FROM web_sales)
),
CustomerDemographics AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
),
TopStores AS (
    SELECT
        s_store_name,
        SUM(ws_sales_price * ws_quantity) AS total_sales
    FROM
        SalesData
    GROUP BY
        s_store_name
    ORDER BY
        total_sales DESC
    LIMIT 5
),
FinalMetrics AS (
    SELECT
        t.s_store_name,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        SUM(CASE WHEN c.cd_credit_rating = 'Good' THEN 1 ELSE 0 END) AS good_credit_count,
        AVG(ws_sales_price) AS avg_sales_price,
        SUM(ws_quantity) AS total_quantity_sold
    FROM
        SalesData s
    JOIN CustomerDemographics c ON s.c_customer_sk = c.c_customer_sk
    JOIN TopStores t ON s.s_store_name = t.s_store_name
    GROUP BY
        t.s_store_name
)

SELECT
    f.s_store_name,
    f.unique_customers,
    f.good_credit_count,
    f.avg_sales_price,
    f.total_quantity_sold
FROM
    FinalMetrics f
WHERE
    f.unique_customers IS NOT NULL
    AND f.total_quantity_sold > 1000
ORDER BY
    f.total_quantity_sold DESC;
