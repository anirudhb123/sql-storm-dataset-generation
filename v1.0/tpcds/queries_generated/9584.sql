
WITH sales_summary AS (
    SELECT 
        w.warehouse_id,
        i.i_item_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_net_paid,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        store_sales AS ss
    JOIN 
        warehouse AS w ON ss.ss_store_sk = w.w_warehouse_sk
    JOIN 
        item AS i ON ss.ss_item_sk = i.i_item_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 2451545 AND 2452300  -- Date filter (example)
    GROUP BY 
        w.warehouse_id, i.i_item_id
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 2451545 AND 2452300  -- Date filter (example)
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
combined_summary AS (
    SELECT 
        ss.warehouse_id,
        SUM(ss.total_quantity) AS warehouse_total_quantity,
        SUM(ss.total_net_paid) AS warehouse_total_net_paid,
        AVG(ss.avg_sales_price) AS warehouse_avg_sales_price,
        SUM(cs.total_transactions) AS customer_total_transactions
    FROM 
        sales_summary AS ss
    LEFT JOIN 
        customer_summary AS cs ON ss.total_transactions > 0
    GROUP BY 
        ss.warehouse_id
)
SELECT 
    warehouse_id,
    warehouse_total_quantity,
    warehouse_total_net_paid,
    warehouse_avg_sales_price,
    customer_total_transactions
FROM 
    combined_summary
ORDER BY 
    warehouse_total_net_paid DESC
LIMIT 10;
