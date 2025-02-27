
WITH RankedSales AS (
    SELECT 
        ws.web_page_sk,
        ws_sold_date_sk,
        ws.net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_page_sk ORDER BY ws.net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
TotalProfit AS (
    SELECT 
        wp.web_page_id,
        SUM(ws.net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    GROUP BY 
        wp.web_page_id
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_college_count,
        DENSE_RANK() OVER (ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    wp.web_page_id,
    SUM(tp.total_net_profit) AS page_total_net_profit,
    cd.gender_summary,
    cd.marital_status_summary,
    COUNT(DISTINCT cd.c_customer_sk) AS customer_count
FROM 
    TotalProfit tp
LEFT JOIN 
    RankedSales rs ON tp.web_page_id = rs.web_page_sk
LEFT JOIN (
    SELECT 
        cd.cd_gender AS gender_summary,
        cd.cd_marital_status AS marital_status_summary,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY COUNT(*) DESC) AS rn
    FROM 
        CustomerDetails cd
    WHERE 
        cd.purchase_rank <= 10
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
) cd ON rs.web_page_sk = cd.gender_summary
GROUP BY 
    wp.web_page_id, cd.gender_summary, cd.marital_status_summary
HAVING 
    COUNT(DISTINCT cd.c_customer_sk) > 5
ORDER BY 
    page_total_net_profit DESC
LIMIT 10;
