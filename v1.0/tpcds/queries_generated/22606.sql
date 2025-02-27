
WITH ranked_sales AS (
    SELECT 
        ws.web_site_id,
        ws.web_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY ws.ext_sales_price DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
top_web_sales AS (
    SELECT 
        web_site_id, 
        web_sales_price
    FROM 
        ranked_sales
    WHERE 
        rank <= 5
),
average_sales AS (
    SELECT 
        web_site_id,
        AVG(web_sales_price) as avg_sales_price
    FROM 
        top_web_sales 
    GROUP BY 
        web_site_id
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        SUM(CASE WHEN coalesce(ws.ws_sales_price, 0) > 0 THEN ws.ws_net_profit ELSE 0 END) AS total_net_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
final_report AS (
    SELECT 
        cs.c_customer_id, 
        cs.cd_gender, 
        cs.cd_marital_status, 
        cs.cd_purchase_estimate, 
        COALESCE(as.avg_sales_price, 0) AS avg_sales_price,
        cs.total_net_profit,
        CASE 
            WHEN cs.total_net_profit > 1000 THEN 'High'
            WHEN cs.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low' 
        END AS profit_category
    FROM 
        customer_summary cs
    LEFT JOIN 
        average_sales as ON cs.c_customer_id = as.web_site_id
)
SELECT 
    f.*, 
    (SELECT STRING_AGG(DISTINCT ws.ws_web_page_sk::TEXT, ',') 
     FROM web_sales ws 
     WHERE ws.ws_bill_customer_sk = f.c_customer_id) AS visited_web_pages
FROM 
    final_report f
WHERE 
    f.avg_sales_price > (
        SELECT AVG(avg_sales_price) FROM average_sales
    ) 
    AND f.total_net_profit IS NOT NULL 
ORDER BY 
    f.total_net_profit DESC
FETCH FIRST 10 ROWS ONLY;
