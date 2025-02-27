
WITH CustomerSpend AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
Demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cs.cs_net_profit) AS total_profit
    FROM 
        customer_demographics cd
    JOIN 
        catalog_sales cs ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
Feedback AS (
    SELECT 
        wp.wp_web_page_sk,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        COUNT(ws.ws_order_number) AS number_of_sales
    FROM 
        web_page wp
    JOIN 
        web_sales ws ON wp.wp_web_page_sk = ws.ws_web_page_sk
    GROUP BY 
        wp.wp_web_page_sk
)
SELECT 
    cs.c_customer_sk,
    cs.total_spent,
    cs.order_count,
    d.cd_gender,
    d.cd_marital_status,
    d.total_profit,
    f.wp_web_page_sk,
    f.avg_net_paid,
    f.number_of_sales
FROM 
    CustomerSpend cs
JOIN 
    Demographics d ON cs.c_customer_sk = d.cd_demo_sk
JOIN 
    Feedback f ON d.cd_gender = CASE WHEN f.avg_net_paid > 100 THEN 'M' ELSE 'F' END
WHERE 
    cs.total_spent > 500
ORDER BY 
    cs.total_spent DESC
LIMIT 100;
