
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rank_price,
        COUNT(DISTINCT ws.ws_bill_customer_sk) OVER (PARTITION BY ws.ws_order_number) AS distinct_customers,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.ws_order_number) AS total_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk 
                                FROM date_dim d 
                                WHERE d.d_year = 2023 AND d.d_moy IN (6, 7))
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_credit_rating
    FROM
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM
        catalog_sales cs
    GROUP BY
        cs.cs_order_number, cs.cs_item_sk
),
outer_joined AS (
    SELECT
        r.ws_order_number AS order_num,
        SUM(ss.total_quantity) AS total_quantity_sold,
        cs.total_sales,
        cs.total_net_profit,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender
    FROM
        ranked_sales r
    LEFT JOIN 
        sales_summary cs ON r.ws_order_number = cs.cs_order_number AND r.ws_item_sk = cs.cs_item_sk
    FULL OUTER JOIN 
        customer_info ci ON r.rank_price = 1 AND r.ws_order_number = ci.c_customer_sk
    WHERE
        cs.total_net_profit IS NOT NULL OR r.ws_sales_price IS NOT NULL
    GROUP BY 
        r.ws_order_number, cs.total_sales, cs.total_net_profit, ci.c_first_name, ci.c_last_name, ci.cd_gender
)
SELECT 
    o.order_num,
    COALESCE(o.total_quantity_sold, 0) AS quantity_sold,
    COALESCE(o.total_sales, 0) AS total_sales,
    o.total_net_profit,
    o.c_first_name,
    o.c_last_name,
    CASE 
        WHEN o.cd_gender = 'M' THEN 'Male'
        WHEN o.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender_description
FROM 
    outer_joined o
WHERE 
    o.total_net_profit > 1000 OR (o.total_sales IS NULL AND o.quantity_sold > 5)
ORDER BY 
    o.order_num DESC, total_net_profit DESC
LIMIT 100;
