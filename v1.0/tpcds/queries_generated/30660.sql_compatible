
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_sold_date_sk, 
        cs_item_sk, 
        SUM(cs_quantity) + sd.total_quantity,
        SUM(cs_net_paid_inc_tax) + sd.total_sales
    FROM 
        catalog_sales cs
    JOIN 
        sales_data sd ON cs.sold_date_sk = sd.ws_sold_date_sk AND cs.item_sk = sd.ws_item_sk
    GROUP BY 
        cs_sold_date_sk, 
        cs_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as rn
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year > 1990
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    SUM(sd.total_quantity) AS total_quantity,
    AVG(sd.total_sales) AS average_sales,
    COUNT(ci.c_customer_sk) FILTER (WHERE ci.cd_marital_status = 'M') AS married_count,
    COUNT(ci.c_customer_sk) FILTER (WHERE ci.cd_marital_status = 'S') AS single_count
FROM 
    customer_info ci
JOIN 
    sales_data sd ON ci.c_customer_sk = sd.ws_item_sk
WHERE 
    ci.rn <= 10
GROUP BY 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.cd_gender
ORDER BY 
    ci.cd_gender, total_quantity DESC;
