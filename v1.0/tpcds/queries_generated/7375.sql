
WITH sales_data AS (
    SELECT
        ws.ws_sales_price,
        cs.cs_sales_price,
        ss.ss_sales_price,
        ws.ws_quantity + cs.cs_quantity + ss.ss_quantity AS total_quantity,
        ws.ws_net_paid + cs.cs_net_paid + ss.ss_net_paid AS total_net_paid
    FROM
        web_sales ws
    FULL OUTER JOIN
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
    FULL OUTER JOIN
        store_sales ss ON ws.ws_item_sk = ss.ss_item_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231
        OR cs.cs_sold_date_sk BETWEEN 20220101 AND 20221231
        OR ss.ss_sold_date_sk BETWEEN 20220101 AND 20221231
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
aggregated_data AS (
    SELECT
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        SUM(sd.total_quantity) AS total_quantity,
        SUM(sd.total_net_paid) AS total_net_paid
    FROM
        customer_info ci
    LEFT JOIN
        sales_data sd ON ci.c_customer_sk = sd.c_customer_sk
    GROUP BY
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.cd_marital_status
)
SELECT
    ad.c_customer_sk,
    ad.c_first_name,
    ad.c_last_name,
    ad.cd_gender,
    ad.cd_marital_status,
    ad.total_quantity,
    ad.total_net_paid,
    CASE 
        WHEN ad.total_net_paid > 1000 THEN 'High Value'
        WHEN ad.total_net_paid BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM
    aggregated_data ad
WHERE
    ad.total_quantity > 0
ORDER BY
    ad.total_net_paid DESC
LIMIT 100;
