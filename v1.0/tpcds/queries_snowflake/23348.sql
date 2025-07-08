
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS rank,
        ws_net_paid,
        ws_quantity,
        ws_sales_price
    FROM web_sales
    WHERE ws_ship_date_sk IS NOT NULL
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        COALESCE(cd.cd_dep_employed_count, 0) AS employed_count,
        COALESCE(cd.cd_dep_college_count, 0) AS college_count,
        DENSE_RANK() OVER (PARTITION BY cd.cd_credit_rating ORDER BY c.c_customer_sk) AS credit_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
join_info AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_net_paid,
        rs.ws_quantity,
        rs.rank
    FROM ranked_sales rs
    JOIN customer_info ci ON ci.c_customer_sk = (SELECT cr_returning_customer_sk FROM catalog_returns cr WHERE cr.cr_item_sk = rs.ws_item_sk LIMIT 1)
    WHERE ci.credit_rank <= 10
),
final_selection AS (
    SELECT 
        ji.c_customer_sk,
        ji.c_first_name,
        ji.c_last_name,
        ji.ws_item_sk,
        ji.ws_order_number,
        ji.ws_net_paid,
        ji.ws_quantity,
        CASE 
            WHEN ji.rank <= 5 THEN 'Top 5'
            WHEN ji.ws_quantity > 10 THEN 'High Volume'
            ELSE 'Regular'
        END AS sale_category
    FROM join_info ji
)
SELECT 
    fs.c_customer_sk,
    fs.c_first_name,
    fs.c_last_name,
    fs.ws_item_sk,
    fs.ws_order_number,
    SUM(fs.ws_net_paid) OVER (PARTITION BY fs.c_customer_sk ORDER BY fs.ws_order_number) AS cumulative_sales,
    fs.sale_category
FROM final_selection fs
WHERE fs.ws_item_sk IN (SELECT DISTINCT cr_item_sk FROM catalog_returns cr WHERE cr.cr_return_quantity > 0)
ORDER BY fs.c_customer_sk, fs.ws_order_number DESC
LIMIT 100;
