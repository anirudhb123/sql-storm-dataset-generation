
WITH RECURSIVE sales_summary AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) as sales_rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk

    UNION ALL

    SELECT
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_sales_price) DESC) as sales_rank
    FROM
        catalog_sales
    GROUP BY
        cs_item_sk
),

combined_sales AS (
    SELECT
        ss_item_sk,
        SUM(total_quantity) AS combined_quantity,
        SUM(total_sales) AS combined_sales
    FROM (
        SELECT ws_item_sk, total_quantity, total_sales FROM sales_summary
        UNION ALL
        SELECT cs_item_sk, total_quantity, total_sales FROM sales_summary
    ) AS all_sales
    GROUP BY ss_item_sk
),

top_items AS (
    SELECT
        cs_item_sk,
        combined_quantity,
        combined_sales,
        RANK() OVER (ORDER BY combined_sales DESC) AS item_rank
    FROM
        combined_sales
    WHERE
        combined_quantity > 0
) 

SELECT
    ci.i_item_id,
    ci.i_item_desc,
    ti.combined_quantity,
    ti.combined_sales,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    NULLIF(ti.combined_sales, 0) / NULLIF(ti.combined_quantity, 0) AS avg_sale_price,
    CASE
        WHEN NULLIF(ti.combined_sales, 0) > 10000 THEN 'High Volume'
        WHEN NULLIF(ti.combined_sales, 0) BETWEEN 5000 AND 10000 THEN 'Moderate Volume'
        ELSE 'Low Volume'
    END AS sales_volume_category
FROM
    top_items ti
JOIN
    item ci ON ci.i_item_sk = ti.cs_item_sk
JOIN
    web_sales ws ON ws.ws_item_sk = ci.i_item_sk
LEFT JOIN
    customer c ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN
    customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
WHERE
    ti.item_rank <= 10
ORDER BY
    ti.combined_sales DESC;
