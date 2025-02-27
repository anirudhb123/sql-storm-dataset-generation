
WITH ranked_sales AS (
    SELECT
        s.s_store_sk,
        s.ss_sold_date_sk,
        s.ss_item_sk,
        SUM(s.ss_quantity) AS total_quantity,
        SUM(s.ss_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(s.ss_sales_price) DESC) AS sales_rank
    FROM
        store_sales s
    JOIN
        store st ON s.s_store_sk = st.s_store_sk
    JOIN
        customer c ON s.ss_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
        AND st.s_state = 'CA'
    GROUP BY
        s.s_store_sk, s.ss_sold_date_sk, s.ss_item_sk
),
top_items AS (
    SELECT
        r.s_store_sk,
        r.ss_item_sk,
        r.total_quantity,
        r.total_sales
    FROM
        ranked_sales r
    WHERE
        r.sales_rank <= 5
)
SELECT 
    st.s_store_name,
    i.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    (ti.total_sales - SUM(cr.cr_return_amount)) AS net_sales
FROM 
    top_items ti
JOIN 
    item i ON ti.ss_item_sk = i.i_item_sk
JOIN 
    store st ON ti.s_store_sk = st.s_store_sk
LEFT JOIN 
    catalog_returns cr ON ti.ss_item_sk = cr.cr_item_sk 
                      AND cr.cr_returned_date_sk = ti.ss_sold_date_sk
GROUP BY 
    st.s_store_name, i.i_item_desc, ti.total_quantity, ti.total_sales
ORDER BY 
    st.s_store_name, net_sales DESC;
