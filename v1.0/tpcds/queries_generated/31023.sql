
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_item_sk) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT d_date_sk FROM date_dim WHERE d_date = CURRENT_DATE)
    UNION ALL
    SELECT 
        cs_order_number,
        cs_item_sk,
        cs_quantity,
        cs_sales_price,
        cs_net_profit,
        ROW_NUMBER() OVER (PARTITION BY cs_order_number ORDER BY cs_item_sk) AS rn
    FROM catalog_sales
    WHERE cs_sold_date_sk = (SELECT d_date_sk FROM date_dim WHERE d_date = CURRENT_DATE)
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(sd.ws_net_profit), 0) AS total_web_sales,
        COALESCE(SUM(sd.cs_net_profit), 0) AS total_catalog_sales,
        (COALESCE(SUM(sd.ws_net_profit), 0) + COALESCE(SUM(sd.cs_net_profit), 0)) AS total_sales
    FROM customer c
    LEFT JOIN sales_data sd ON c.c_customer_sk = sd.ws_bill_customer_sk OR c.c_customer_sk = sd.cs_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
ranking AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM customer_summary cs
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.total_web_sales,
    r.total_catalog_sales,
    r.total_sales,
    r.sales_rank,
    CASE 
        WHEN r.total_sales IS NULL THEN 'No Sales'
        WHEN r.total_sales > 1000 THEN 'High Value Customer'
        WHEN r.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value
FROM ranking r
WHERE r.sales_rank <= 10
ORDER BY r.sales_rank;
