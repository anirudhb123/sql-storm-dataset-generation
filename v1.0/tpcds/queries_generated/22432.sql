
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        (SELECT COUNT(*)
         FROM store_sales ss
         WHERE ss.ss_customer_sk = c.c_customer_sk) AS total_store_purchases,
        (SELECT SUM(ws.ws_sales_price) 
         FROM web_sales ws
         WHERE ws.ws_bill_customer_sk = c.c_customer_sk
           AND ws.ws_ship_date_sk IS NOT NULL) AS total_web_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
),
high_value_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_credit_rating,
        ci.total_store_purchases,
        ci.total_web_sales,
        (CASE 
            WHEN ci.total_store_purchases > 10 AND ci.total_web_sales > 1000 THEN 'High Value'
            ELSE 'Regular'
        END) AS customer_value_status
    FROM 
        customer_info ci
    WHERE 
        ci.total_store_purchases IS NOT NULL
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_sk,
        COUNT(DISTINCT id.i_item_sk) AS total_items,
        MAX(i.i_current_price) AS max_item_price,
        MIN(i.i_current_price) AS min_item_price,
        SUM(i.i_current_price) AS total_inventory_value
    FROM 
        warehouse w
    JOIN 
        inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN 
        item i ON i.i_item_sk = inv.inv_item_sk
    GROUP BY 
        w.w_warehouse_sk
),
sales_summary AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        ss.ss_store_sk
)
SELECT 
    wu.*,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.customer_value_status
FROM 
    warehouse_summary wu
LEFT JOIN 
    high_value_customers hvc ON wu.w_warehouse_sk = (SELECT w_warehouse_sk FROM inventory WHERE inv_item_sk IN (SELECT i_item_sk FROM web_sales WHERE ws_bill_customer_sk = hvc.c_customer_sk) LIMIT 1)
WHERE 
    wu.total_inventory_value > 10000
    AND (hvc.cd_credit_rating IS NULL OR hvc.cd_credit_rating <> 'Poor')
UNION ALL
SELECT 
    ss.total_quantity,
    ss.total_transactions,
    ss.total_net_profit,
    'Aggregate Sales Summary' AS notation,
    NULL AS customer_first_name,
    NULL AS customer_last_name,
    NULL AS value_status
FROM 
    sales_summary ss
WHERE 
    ss.total_net_profit > 5000;
