
WITH RECURSIVE date_series AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_date > '2022-01-01'
    UNION ALL
    SELECT d_date_sk + 1, d_date + INTERVAL '1 DAY'
    FROM date_series
    WHERE d_date_sk + 1 <= (SELECT MAX(d_date_sk) FROM date_dim)
),
customer_data AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        windowed_sales.total_sales,
        windowed_sales.sale_count,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY windowed_sales.total_sales DESC) AS sales_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN (
        SELECT 
            ws.bill_customer_sk,
            SUM(ws.net_paid_inc_tax) AS total_sales,
            COUNT(ws.order_number) AS sale_count
        FROM web_sales ws
        INNER JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
        WHERE dd.d_year = 2022
        GROUP BY ws.bill_customer_sk
    ) AS windowed_sales ON c.c_customer_sk = windowed_sales.bill_customer_sk
)
SELECT 
    cd.c_customer_id,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    COALESCE(cd.total_sales, 0) AS total_sales,
    COALESCE(cd.sale_count, 0) AS sale_count,
    ds.d_date,
    CASE 
        WHEN cd.total_sales IS NULL THEN 'No Sales'
        WHEN cd.total_sales < 100 THEN 'Low Value'
        WHEN cd.total_sales BETWEEN 100 AND 500 THEN 'Medium Value'
        ELSE 'High Value'
    END AS customer_value_category,
    CASE 
        WHEN cd.cd_gender IS NULL THEN 'Unknown'
        ELSE cd.cd_gender
    END AS gender_description,
    COUNT(DISTINCT cs.cs_item_sk) FILTER (WHERE cs.cs_net_profit > 0) AS profitable_items,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.sales_rank) AS numeric_customer_rank,
    STRING_AGG(DISTINCT CONCAT(i.i_item_desc, ' (', i.i_item_id, ')')) AS bought_items_list
FROM customer_data cd
LEFT JOIN catalog_sales cs ON cd.sale_count > 0 AND cs.cs_bill_customer_sk = cd.c_customer_sk
LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
CROSS JOIN date_series ds
ON ds.d_date = CURRENT_DATE
GROUP BY 
    cd.c_customer_id, 
    cd.c_first_name, 
    cd.c_last_name, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_credit_rating, 
    ds.d_date
ORDER BY cd.sales_rank ASC NULLS LAST, cd.c_last_name ASC, cd.c_first_name ASC;
