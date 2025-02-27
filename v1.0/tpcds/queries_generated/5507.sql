
WITH customer_details AS (
    SELECT 
        c.c_customer_id,
        CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        ws.ws_web_site_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_web_site_sk
),
detailed_sales AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS sold_quantity,
        SUM(ss.ss_net_profit) AS net_profit,
        s.s_store_id,
        s.s_store_name
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY 
        ss.ss_item_sk, s.s_store_id, s.s_store_name
)
SELECT 
    cd.c_customer_id,
    cd.gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    ss.total_quantity AS total_web_sales_quantity,
    ss.total_net_profit AS total_web_sales_profit,
    ds.sold_quantity AS store_sales_quantity,
    ds.net_profit AS store_net_profit,
    ds.s_store_id,
    ds.s_store_name
FROM 
    customer_details cd
LEFT JOIN 
    sales_summary ss ON cd.c_customer_id = (
        SELECT 
            MAX(ws_bill_customer_sk)
        FROM 
            web_sales ws
        WHERE 
            ws_bill_customer_sk IS NOT NULL
    )
LEFT JOIN 
    detailed_sales ds ON cd.c_customer_id = (
        SELECT 
            MAX(ss_customer_sk)
        FROM 
            store_sales ss
        WHERE 
            ss_customer_sk IS NOT NULL
    )
WHERE 
    cd.cd_purchase_estimate > 1000
ORDER BY 
    cd.c_customer_id;
