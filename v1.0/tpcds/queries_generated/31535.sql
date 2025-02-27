
WITH RECURSIVE sales_data AS (
    SELECT
        ss_sold_date_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_sales,
        SUM(ss_net_paid) AS total_revenue
    FROM
        store_sales
    GROUP BY
        ss_sold_date_sk, ss_item_sk
    UNION ALL
    SELECT
        sd.ss_sold_date_sk,
        sd.ss_item_sk,
        SUM(sd.ss_quantity) + SUM(s.total_sales) AS total_sales,
        SUM(sd.ss_net_paid) + SUM(s.total_revenue) AS total_revenue
    FROM
        store_sales sd
    JOIN
        sales_data s ON sd.ss_item_sk = s.ss_item_sk AND sd.ss_sold_date_sk = s.ss_sold_date_sk + 1
    GROUP BY
        sd.ss_sold_date_sk, sd.ss_item_sk
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
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ranked_sales AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY ss_item_sk ORDER BY total_revenue DESC) AS revenue_rank
    FROM
        (
            SELECT
                sd.ss_item_sk,
                SUM(sd.total_sales) AS item_sales,
                SUM(sd.total_revenue) AS item_revenue
            FROM
                sales_data sd
            GROUP BY
                sd.ss_item_sk
        ) AS grouped_sales
)
SELECT
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    rs.item_sales,
    rs.item_revenue,
    CASE 
        WHEN rs.revenue_rank <= 10 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS sales_classification
FROM
    ranked_sales rs
JOIN
    customer_info ci ON ci.c_customer_sk = (SELECT sr_customer_sk FROM store_returns WHERE sr_item_sk = rs.ss_item_sk LIMIT 1)
WHERE
    ci.cd_gender IS NOT NULL AND
    rs.item_sales > 100
ORDER BY
    rs.item_revenue DESC
LIMIT 50;
