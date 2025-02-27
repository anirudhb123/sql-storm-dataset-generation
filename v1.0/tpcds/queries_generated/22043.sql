
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_web_site_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk, ws_web_site_sk
),
top_customers AS (
    SELECT 
        ca_address_id, 
        cd_gender, 
        cd_marital_status,  
        total_net_profit,
        profit_rank
    FROM 
        ranked_sales
    JOIN customer ON ranked_sales.ws_bill_customer_sk = customer.c_customer_sk
    JOIN customer_demographics ON customer.c_current_cdemo_sk = cd_demo_sk
    JOIN customer_address ON customer.c_current_addr_sk = ca_address_sk
    WHERE 
        profit_rank <= 10 AND 
        (cd_gender = 'M' AND (total_net_profit IS NOT NULL OR cd_marital_status IS NULL))
),
excessive_promotion AS (
    SELECT 
        p_promo_name,
        COUNT(*) AS promo_count 
    FROM 
        promotion 
    JOIN web_sales ON promotion.p_promo_sk = web_sales.ws_promo_sk
    GROUP BY 
        p_promo_name
    HAVING 
        COUNT(*) > 100
),
comprehensive_report AS (
    SELECT 
        tc.ca_address_id,
        tc.cd_gender,
        tc.cd_marital_status,
        ep.promo_name,
        COALESCE(ep.promo_count, 0) AS promo_count,
        CASE 
            WHEN tc.total_net_profit IS NULL THEN 'No Profit Data'
            WHEN tc.total_net_profit > 1000 THEN 'High Profit'
            ELSE 'Average Profit'
        END AS profit_category
    FROM 
        top_customers tc
    LEFT JOIN 
        excessive_promotion ep ON tc.total_net_profit = ep.promo_count
)
SELECT 
    cr.ca_country AS address_country, 
    cr.cd_gender AS customer_gender, 
    cr.promo_name AS promotional_campaign,
    SUM(CASE 
        WHEN profit_category = 'High Profit' THEN 1 
        ELSE 0 
    END) AS high_profit_customers,
    AVG(total_net_profit) AS average_net_profit
FROM 
    comprehensive_report cr
WHERE 
    cr.promo_count IS NOT NULL
GROUP BY 
    cr.ca_country, cr.cd_gender, cr.promo_name
ORDER BY 
    high_profit_customers DESC, 
    average_net_profit DESC
LIMIT 50;
