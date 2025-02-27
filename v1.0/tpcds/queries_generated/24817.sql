
WITH RECURSIVE income_categories AS (
    SELECT 
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        CASE 
            WHEN ib_lower_bound < 10000 THEN 'Low'
            WHEN ib_lower_bound BETWEEN 10000 AND 50000 THEN 'Medium'
            ELSE 'High'
        END AS income_category
    FROM income_band
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_dep_count,
        ca.ca_zip,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_zip ORDER BY cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    INNER JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_info AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS unique_sales
    FROM 
        web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        ws.ws_item_sk
),
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        SUM(si.total_net_profit) AS total_spent,
        SUM(si.total_quantity) AS total_items,
        COUNT(*) OVER (PARTITION BY ci.c_zip_code) AS zip_sales_count
    FROM 
        customer_info ci
    LEFT JOIN sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.cd_marital_status
    HAVING 
        SUM(si.total_net_profit) > 1000
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_spent,
    ic.income_category,
    COALESCE(NULLIF(tc.zip_sales_count, 0), 'No Sales') AS sales_count_status
FROM 
    top_customers tc
LEFT JOIN income_categories ic ON tc.total_spent BETWEEN ic.ib_lower_bound AND ic.ib_upper_bound
WHERE 
    (tc.cd_gender = 'F' OR tc.cd_marital_status <> 'S')
ORDER BY 
    total_spent DESC,
    c_last_name ASC
FETCH FIRST 100 ROWS ONLY;
