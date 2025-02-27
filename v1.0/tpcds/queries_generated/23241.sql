
WITH RECURSIVE SalesData AS (
    SELECT
        cs_item_sk AS item_sk,
        SUM(cs_quantity) AS total_sold,
        SUM(cs_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_paid) DESC) AS sales_rank
    FROM
        catalog_sales
    GROUP BY
        cs_item_sk
),
IncomeBandData AS (
    SELECT
        hd_income_band_sk,
        COUNT(hd_demo_sk) AS num_customers,
        SUM(hd_dep_count) AS total_dependents
    FROM
        household_demographics
    GROUP BY
        hd_income_band_sk
    HAVING
        COUNT(hd_demo_sk) > 10
),
HighValueItems AS (
    SELECT
        item.i_item_id,
        item.i_item_desc,
        item.i_current_price,
        sales.total_revenue
    FROM
        item
    JOIN SalesData sales
        ON item.i_item_sk = sales.item_sk
    WHERE
        sales.total_revenue > (SELECT AVG(total_revenue) * 1.2 FROM SalesData)
),
CustomerInfo AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        CASE 
            WHEN c.c_birth_year IS NULL THEN 'Unknown'
            ELSE CAST(EXTRACT(YEAR FROM CURRENT_DATE) - c.c_birth_year AS VARCHAR)
        END AS age,
        COALESCE(cd.cd_gender, 'Not Specified') AS gender
    FROM
        customer c
    LEFT JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.age,
    ci.gender,
    SUM(ws.ws_net_paid) AS total_spent,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    ARRAY_AGG(DISTINCT hi.i_item_desc) AS purchased_items,
    ib.num_customers AS income_band_customers,
    ib.total_dependents AS total_dependents
FROM
    CustomerInfo ci
JOIN web_sales ws
    ON ci.c_customer_sk = ws.ws_bill_customer_sk
JOIN HighValueItems hi
    ON hi.i_item_id = ws.ws_item_sk
JOIN IncomeBandData ib
    ON ci.c_customer_sk = ib.hd_demo_sk
GROUP BY
    ci.c_customer_id, ci.c_first_name, ci.c_last_name, ci.age, ci.gender, ib.num_customers, ib.total_dependents
HAVING
    SUM(ws.ws_net_paid) > (SELECT AVG(ws_net_paid) FROM web_sales WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim))
ORDER BY
    total_spent DESC
LIMIT 100;
