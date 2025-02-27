
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
top_sales AS (
    SELECT
        s.ws_item_sk,
        s.total_quantity,
        s.total_sales,
        COALESCE(i.i_item_desc, 'Unknown Item') AS item_description,
        ROW_NUMBER() OVER (ORDER BY s.total_sales DESC) AS item_rank
    FROM sales_summary s
    LEFT JOIN item i ON s.ws_item_sk = i.i_item_sk
    WHERE s.total_sales > 1000
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_count,
        cd.cd_credit_rating,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_dep_count, cd.cd_credit_rating
),
high_value_customers AS (
    SELECT 
        ci.c_customer_id,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_dep_count,
        ci.cd_credit_rating,
        ci.total_spent,
        CASE 
            WHEN ci.total_spent > 10000 THEN 'VIP'
            WHEN ci.total_spent BETWEEN 5000 AND 10000 THEN 'Gold'
            ELSE 'Regular'
        END AS customer_tier
    FROM customer_info ci
    WHERE ci.total_spent IS NOT NULL
),
return_summary AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM store_returns
    GROUP BY sr_item_sk
)
SELECT 
    t.item_rank,
    t.item_description,
    t.total_sales,
    hvc.customer_tier,
    hvc.total_spent,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_value, 0) AS total_return_value,
    CASE
        WHEN hvc.total_spent IS NULL THEN 'No Purchase'
        ELSE 'Purchase Made'
    END AS purchase_status
FROM top_sales t
JOIN high_value_customers hvc ON t.ws_item_sk = hvc.c_customer_id
LEFT JOIN return_summary rs ON t.ws_item_sk = rs.sr_item_sk
WHERE t.item_rank <= 10
ORDER BY t.total_sales DESC, hvc.total_spent DESC;
