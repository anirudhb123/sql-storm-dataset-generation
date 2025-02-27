
WITH sales_summary AS (
    SELECT 
        COALESCE(ws_bill_customer_sk, ss_customer_sk, cs_bill_customer_sk) AS customer_id,
        SUM(COALESCE(ws_net_profit, 0) + COALESCE(ss_net_profit, 0) + COALESCE(cs_net_profit, 0)) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS web_orders,
        COUNT(DISTINCT ss_ticket_number) AS store_orders,
        COUNT(DISTINCT cs_order_number) AS catalog_orders
    FROM 
        web_sales ws
        FULL OUTER JOIN store_sales ss ON ws.ws_item_sk = ss.ss_item_sk
        FULL OUTER JOIN catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
    GROUP BY 
        customer_id
),
customer_demos AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cd.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(ss.ext_sales_price) AS total_sales,
    AVG(ss.ext_discount_amt) AS average_discount,
    ss.web_orders,
    ss.store_orders,
    ss.catalog_orders,
    CASE 
        WHEN ss.total_profit > 1000 THEN 'High Value'
        WHEN ss.total_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    sales_summary ss
    JOIN customer_demos cd ON ss.customer_id = cd.c_customer_sk
WHERE
    cd.cd_gender IS NOT NULL
    AND cd.cd_marital_status IN ('M', 'S')
GROUP BY 
    cd.c_customer_sk, cd.cd_gender, cd.cd_marital_status, ss.web_orders, ss.store_orders, ss.catalog_orders
HAVING 
    SUM(ss.ext_sales_price) > 100
ORDER BY 
    total_sales DESC
FETCH FIRST 10 ROWS ONLY;
