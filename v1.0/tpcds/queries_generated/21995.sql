
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ws.ws_sales_price, 
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sales_price IS NOT NULL
),
filtered_sales AS (
    SELECT
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        CASE
            WHEN rs.sales_rank <= 5 THEN 'Top 5 Sale'
            ELSE 'Others'
        END AS sale_category
    FROM ranked_sales rs
),
distinct_customers AS (
    SELECT DISTINCT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_count,
        ca.ca_city
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_city IS NOT NULL
),
sales_summary AS (
    SELECT 
        fs.ws_item_sk,
        COUNT(DISTINCT dc.c_customer_id) AS distinct_customer_count,
        SUM(fs.ws_sales_price) AS total_sales_value
    FROM filtered_sales fs
    JOIN distinct_customers dc ON fs.ws_item_sk = dc.c_customer_id
    GROUP BY fs.ws_item_sk
)
SELECT 
    fs.ws_item_sk,
    ss.distinct_customer_count,
    ss.total_sales_value,
    CASE 
        WHEN ss.total_sales_value IS NULL THEN 'No Sales'
        WHEN ss.total_sales_value < 1000 THEN 'Low Sales'
        WHEN ss.total_sales_value BETWEEN 1000 AND 5000 THEN 'Moderate Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM filtered_sales fs
FULL OUTER JOIN sales_summary ss ON fs.ws_item_sk = ss.ws_item_sk
WHERE fs.sale_category = 'Top 5 Sale'
OR ss.distinct_customer_count IS NULL
ORDER BY fs.ws_item_sk, sales_category DESC
FETCH FIRST 100 ROWS ONLY;
