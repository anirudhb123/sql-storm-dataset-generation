
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_sales_price) AS total_sales
    FROM 
        catalog_sales
    GROUP BY 
        cs_sold_date_sk, cs_item_sk
),
customer_info AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        sales_summary s ON ss.ss_item_sk = s.ws_item_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_purchase_estimate > 500
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_income_band_sk,
    COALESCE(ci.total_net_profit, 0) AS total_net_profit,
    COALESCE(ci.purchase_count, 0) AS purchase_count,
    ROW_NUMBER() OVER (PARTITION BY ci.cd_gender ORDER BY ci.total_net_profit DESC) AS rank_within_gender,
    CASE 
        WHEN ci.total_net_profit > (SELECT AVG(total_net_profit) FROM customer_info) THEN 'Above Average'
        ELSE 'Below Average'
    END AS performance_category
FROM 
    customer_info ci
WHERE 
    ci.cd_income_band_sk IS NOT NULL
ORDER BY 
    ci.total_net_profit DESC;
