
WITH RECURSIVE item_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rn
    FROM web_sales
    GROUP BY ws_item_sk
), 
customer_stats AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Unknown'
        END AS gender,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(COALESCE(ws_ext_sales_price, 0)) AS total_spent,
        DENSE_RANK() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS spending_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender
), 
item_sales_info AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc,
        is.total_quantity,
        is.total_sales,
        (SELECT COUNT(DISTINCT ws_order_number) FROM web_sales WHERE ws_item_sk = i.i_item_sk) AS order_count
    FROM item i
    JOIN item_sales is ON i.i_item_sk = is.ws_item_sk
)
SELECT 
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.gender,
    isInfo.i_item_id,
    isInfo.i_item_desc,
    isInfo.total_quantity,
    isInfo.total_sales,
    isInfo.order_count,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'Not Available' 
        WHEN cs.total_spent > 1000 THEN 'High Roller'
        WHEN cs.total_spent BETWEEN 500 AND 1000 THEN 'Mid Tier'
        ELSE 'Low Spender'
    END AS spending_category
FROM customer_stats cs
JOIN item_sales_info isInfo ON cs.spending_rank = 1
LEFT JOIN inventory inv ON isInfo.i_item_id = inv.inv_item_sk
WHERE inv.inv_quantity_on_hand > 0
    AND (inv.inv_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = EXTRACT(YEAR FROM CURRENT_DATE) AND d.d_moy < 6))
ORDER BY cs.total_orders DESC, isInfo.total_sales DESC
FETCH FIRST 10 ROWS ONLY;
