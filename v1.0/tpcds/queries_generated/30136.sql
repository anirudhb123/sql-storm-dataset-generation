
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        s_sales AS total_sales,
        s_leftover_stock AS leftover_inventory
    FROM (
        SELECT 
            s.s_store_sk,
            s.s_store_name,
            s.s_number_employees,
            SUM(ws.ws_ext_sales_price) AS s_sales,
            (SELECT SUM(inv.inv_quantity_on_hand) 
             FROM inventory inv 
             WHERE inv.inv_warehouse_sk = ws.ws_warehouse_sk 
             AND inv.inv_date_sk <= '2023-10-01'
            ) AS s_leftover_stock
        FROM store s
        JOIN web_sales ws ON ws.ws_store_sk = s.s_store_sk
        GROUP BY s.s_store_sk, s.s_store_name, s.s_number_employees
    ) AS store_sales
    WHERE s_sales > 10000
    UNION ALL
    SELECT 
        sh.s_store_sk,
        sh.s_store_name,
        sh.s_number_employees,
        sh.total_sales + sh.income_sales_delta AS total_sales,
        sh.leftover_inventory - (sh.total_sales * 0.05) AS leftover_inventory
    FROM sales_hierarchy sh
    JOIN income_band ib ON sh.s_store_sk = ib.ib_income_band_sk
    WHERE sh.leftover_inventory > 0
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(CONCAT_WS('-', cr.cr_return_quantity, cr.cr_return_amount)) AS total_returns
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returning_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
max_sales AS (
    SELECT 
        ws.ws_item_sk,
        MAX(ws.ws_net_paid) AS max_net_paid
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
final_summary AS (
    SELECT 
        sh.s_store_name,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.total_returns,
        ms.max_net_paid
    FROM sales_hierarchy sh
    LEFT JOIN customer_info ci ON ci.c_customer_sk = (SELECT min(c_customer_sk) FROM customer)
    JOIN max_sales ms ON ms.ws_item_sk = (SELECT min(ws_item_sk) FROM web_sales)
)
SELECT 
    fs.s_store_name,
    fs.c_first_name,
    fs.c_last_name,
    COALESCE(fs.cd_gender, 'Unknown') AS gender,
    fs.total_returns,
    CASE 
        WHEN fs.max_net_paid IS NOT NULL THEN fs.max_net_paid 
        ELSE 0 
    END AS max_net_paid,
    CONCAT('Total Returns: ', CAST(fs.total_returns AS VARCHAR), ' for customer: ', fs.c_first_name, ' ', fs.c_last_name) AS return_details
FROM final_summary fs
WHERE fs.total_returns IS NOT NULL
ORDER BY fs.s_store_name, fs.c_last_name;
