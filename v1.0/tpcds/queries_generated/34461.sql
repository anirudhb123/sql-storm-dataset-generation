
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        c_current_cdemo_sk,
        1 AS level
    FROM 
        customer
    WHERE 
        c_first_shipto_date_sk IS NOT NULL

    UNION ALL

    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        c.c_current_cdemo_sk,
        ch.level + 1
    FROM 
        customer c
    JOIN 
        CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
)
SELECT 
    ch.c_customer_sk, 
    ch.c_first_name || ' ' || ch.c_last_name AS full_name, 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(web.web_page_sk) AS web_page_count,
    SUM(ws.ws_sales_price) AS total_sales,
    AVG(ws.ws_net_profit) AS average_net_profit,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY total_sales DESC) AS rank_by_sales,
    DENSE_RANK() OVER (PARTITION BY cd.cd_marital_status ORDER BY average_net_profit DESC) AS rank_by_profit,
    COALESCE(MAX(p.p_promo_id), 'No Promo') AS promo_used
FROM 
    CustomerHierarchy ch
LEFT JOIN 
    customer_demographics cd ON ch.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON ch.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    web_page web ON ws.ws_web_page_sk = web.wp_web_page_sk
LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE 
    cd.cd_purchase_estimate > 1000 
    AND ch.level > 1
GROUP BY 
    ch.c_customer_sk, 
    ch.c_first_name, 
    ch.c_last_name, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_education_status
ORDER BY 
    total_sales DESC, average_net_profit DESC
LIMIT 100
OFFSET 0;
