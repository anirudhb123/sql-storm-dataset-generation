
WITH Ranked_Customer AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY cd.cd_marital_status ORDER BY COUNT(DISTINCT ws.ws_order_number) DESC) AS rank_by_orders
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
Top_Customers AS (
    SELECT 
        full_name,
        cd_gender,
        cd_marital_status,
        total_orders
    FROM 
        Ranked_Customer
    WHERE 
        rank_by_orders <= 10
)
SELECT 
    tc.full_name,
    tc.cd_gender,
    tc.cd_marital_status,
    ROUND(SUM(wp.wp_char_count) / COUNT(wp.wp_web_page_sk), 2) AS avg_char_count_per_page,
    COUNT(DISTINCT wr.wr_order_number) AS total_web_returns
FROM 
    Top_Customers AS tc
LEFT JOIN 
    web_page AS wp ON wp.wp_customer_sk = tc.c_customer_sk
LEFT JOIN 
    web_returns AS wr ON wr.w_returning_customer_sk = tc.c_customer_sk
GROUP BY 
    tc.full_name, tc.cd_gender, tc.cd_marital_status
ORDER BY 
    total_orders DESC;
