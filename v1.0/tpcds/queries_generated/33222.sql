
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
),
inventory_summary AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
),
profit_summary AS (
    SELECT
        ss_item_sk,
        SUM(ss_net_profit) AS total_net_profit,
        SUM(ss_quantity) AS total_sold
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
),
customer_details AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        COALESCE(hd_income_band_sk, 0) AS income_band,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        customer c
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c_customer_sk, c_first_name, c_last_name, cd_gender, cd_marital_status, 
        cd_purchase_estimate, hd_income_band_sk
)
SELECT
    c.c_first_name,
    c.c_last_name,
    cd.order_count,
    COALESCE(SUM(i.total_quantity_on_hand), 0) AS total_inventory,
    COALESCE(SUM(p.total_net_profit), 0) AS total_net_profit,
    (SELECT COUNT(*) FROM date_dim d WHERE d.d_date BETWEEN '2021-01-01' AND CURRENT_DATE) AS total_days
FROM 
    customer_details cd
    JOIN customer c ON c.c_customer_sk = cd.c_customer_sk
    LEFT JOIN inventory_summary i ON i.inv_item_sk IN (
        SELECT ws_item_sk FROM sales_cte WHERE rn = 1
    )
    LEFT JOIN profit_summary p ON p.ss_item_sk IN (
        SELECT ws_item_sk FROM sales_cte WHERE rn = 1
    )
WHERE 
    cd.order_count > 0
GROUP BY 
    c.c_first_name, c.c_last_name, cd.order_count
HAVING 
    total_inventory > 0 OR total_net_profit > 0
ORDER BY 
    c.c_last_name, c.c_first_name;
