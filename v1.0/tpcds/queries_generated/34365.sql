
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_closed_date_sk,
        s_number_employees,
        1 AS level
    FROM 
        store
    WHERE 
        s_closed_date_sk IS NULL

    UNION ALL

    SELECT 
        s.store_sk, 
        s.s_store_name, 
        s.s_closed_date_sk, 
        s.s_number_employees, 
        sh.level + 1
    FROM 
        store s
    INNER JOIN 
        sales_hierarchy sh ON s.s_store_sk = sh.s_store_sk
    WHERE 
        sh.level < 5
), sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
), demographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cb.ib_income_band_sk,
        SUM(cr.cr_return_amount) AS total_returns
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics cb ON cb.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN 
        catalog_returns cr ON cr.cr_returning_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cb.ib_income_band_sk
), aggregated_sales AS (
    SELECT 
        sh.s_store_name,
        d.cd_gender,
        d.cd_marital_status,
        SUM(sd.total_quantity) AS total_saved_quantity,
        SUM(sd.total_profit) AS total_savings
    FROM 
        sales_hierarchy sh
    LEFT JOIN 
        demographics d ON sh.s_store_sk = d.c_customer_sk
    LEFT JOIN 
        sales_data sd ON sd.ws_item_sk = sh.s_store_sk
    GROUP BY 
        sh.s_store_name, d.cd_gender, d.cd_marital_status
)

SELECT 
    a.s_store_name,
    a.cd_gender,
    a.cd_marital_status,
    COALESCE(a.total_saved_quantity, 0) AS total_saved_quantity,
    COALESCE(a.total_savings, 0) AS total_savings,
    CASE 
        WHEN a.total_saved_quantity > 100 THEN 'High Performer'
        WHEN a.total_saved_quantity BETWEEN 50 AND 100 THEN 'Average Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    aggregated_sales a
ORDER BY 
    total_savings DESC, a.s_store_name;
