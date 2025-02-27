
WITH RECURSIVE sales_trend AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT
        d.d_date_sk,
        st.ws_item_sk,
        SUM(st.total_sales) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY st.ws_item_sk ORDER BY d.d_date_sk) AS sales_rank
    FROM
        sales_trend st
    JOIN
        date_dim d ON d.d_date_sk = st.ws_sold_date_sk + 1
    WHERE
        st.sales_rank < 30
    GROUP BY
        d.d_date_sk, st.ws_item_sk
),
item_performance AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        COALESCE(SUM(st.total_sales), 0) AS total_sales,
        CASE 
            WHEN COALESCE(SUM(st.total_sales), 0) > 10000 THEN 'High'
            WHEN COALESCE(SUM(st.total_sales), 0) BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM
        item i
    LEFT JOIN
        sales_trend st ON i.i_item_sk = st.ws_item_sk
    GROUP BY
        i.i_item_id, i.i_item_desc
),
customer_insights AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count,
        SUM(ws.ws_net_paid) AS total_spent,
        RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS spender_rank
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id, c.c_first_name, c.c_last_name
)
SELECT
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.orders_count,
    ci.total_spent,
    ip.i_item_id,
    ip.i_item_desc,
    ip.total_sales,
    ip.sales_category
FROM
    customer_insights ci
JOIN
    item_performance ip ON ci.spender_rank <= 10
LEFT JOIN 
    store_sales ss ON ip.total_sales > 5000 AND ss.ss_item_sk = ip.i_item_sk
WHERE
    (ci.total_spent IS NOT NULL AND ci.total_spent > 0)
ORDER BY
    ci.total_spent DESC, ip.total_sales DESC
LIMIT 50;
