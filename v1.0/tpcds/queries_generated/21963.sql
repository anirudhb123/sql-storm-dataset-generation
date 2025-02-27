
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_qty_total,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY ws.ws_net_profit DESC) AS rank_profit,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.web_site_id) AS total_net_profit
    FROM 
        web_sales AS ws
    JOIN 
        customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1995
    AND 
        ws.ws_sales_price IS NOT NULL
    AND 
        (ws.ws_net_paid_inc_tax IS NOT NULL OR ws.ws_net_paid_inc_ship IS NOT NULL)
),

CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics AS cd
    LEFT JOIN 
        customer AS c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status
    HAVING 
        COUNT(DISTINCT c.c_customer_sk) > 5
),

PromotionDetails AS (
    SELECT 
        p.p_promo_id,
        p.p_discount_active,
        COUNT(DISTINCT ws.ws_order_number) AS sales_count
    FROM 
        promotion AS p
    LEFT JOIN 
        web_sales AS ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE 
        p.p_start_date_sk <= CURRENT_DATE AND 
        (p.p_end_date_sk IS NULL OR p.p_end_date_sk > CURRENT_DATE)
    GROUP BY 
        p.p_promo_id, p.p_discount_active
    HAVING 
        COUNT(DISTINCT ws.ws_order_number) >= 10
)

SELECT 
    rs.web_site_id,
    rs.ws_order_number,
    rs.ws_sold_date_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    pd.p_promo_id,
    rs.total_net_profit,
    rs.rank_profit,
    CASE 
        WHEN rs.rank_profit = 1 THEN 'Top Seller'
        WHEN rs.rank_profit <= 10 THEN 'High Performer'
        ELSE 'Regular Seller'
    END AS sales_category
FROM 
    RankedSales AS rs
JOIN 
    CustomerDemographics AS cd ON rs.rank_profit BETWEEN 1 AND 5
FULL OUTER JOIN 
    PromotionDetails AS pd ON rs.total_net_profit > 1000
WHERE 
    (rs.total_net_profit IS NOT NULL OR pd.sales_count >= 10)
ORDER BY 
    rs.rank_profit, cd.customer_count DESC, rs.total_net_profit DESC
LIMIT 50;

