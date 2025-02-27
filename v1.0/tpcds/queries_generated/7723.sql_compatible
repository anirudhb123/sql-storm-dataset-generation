
WITH customer_sales AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM
        customer AS c
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales AS cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY
        c.c_customer_id
),
sales_by_demographics AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(cs.total_web_sales) AS total_web_sales,
        SUM(cs.total_catalog_sales) AS total_catalog_sales,
        SUM(cs.total_store_sales) AS total_store_sales
    FROM
        customer_sales AS cs
    JOIN customer_demographics AS cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
top_selling_items AS (
    SELECT
        i.i_item_id,
        COUNT(ws.ws_order_number) AS total_sales,
        SUM(ws.ws_ext_sales_price) AS total_revenue
    FROM
        web_sales AS ws
    JOIN item AS i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY
        i.i_item_id
    ORDER BY
        total_revenue DESC
    LIMIT 10
)
SELECT
    sd.cd_gender,
    sd.cd_marital_status,
    sd.cd_education_status,
    sd.total_web_sales,
    sd.total_catalog_sales,
    sd.total_store_sales,
    ti.i_item_id,
    ti.total_sales,
    ti.total_revenue
FROM
    sales_by_demographics AS sd
JOIN top_selling_items AS ti ON sd.total_web_sales > 10000
ORDER BY
    sd.total_web_sales DESC, ti.total_revenue DESC;
