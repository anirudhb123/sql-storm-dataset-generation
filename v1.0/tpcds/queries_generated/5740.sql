
WITH Customer_Sales AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_ext_sales_price) AS avg_order_value,
        cd.cd_gender,
        cd.cd_marital_status
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        c.c_birth_year BETWEEN 1970 AND 1995
    GROUP BY
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
Demographic_Averages AS (
    SELECT
        cd_gender,
        cd_marital_status,
        AVG(total_sales) AS avg_total_sales,
        AVG(order_count) AS avg_order_count,
        AVG(avg_order_value) AS avg_order_value
    FROM
        Customer_Sales
    GROUP BY
        cd_gender, cd_marital_status
)
SELECT
    d.cd_gender,
    d.cd_marital_status,
    d.avg_total_sales,
    d.avg_order_count,
    d.avg_order_value,
    COUNT(DISTINCT c.c_customer_id) AS customer_count
FROM
    Demographic_Averages d
JOIN
    customer c ON c.c_current_cdemo_sk = (
        SELECT cd_demo_sk FROM customer_demographics WHERE (
            cd_gender = d.cd_gender AND cd_marital_status = d.cd_marital_status
        )
    )
GROUP BY
    d.cd_gender, d.cd_marital_status, d.avg_total_sales, d.avg_order_count, d.avg_order_value
ORDER BY
    d.cd_gender, d.cd_marital_status
LIMIT 10;
