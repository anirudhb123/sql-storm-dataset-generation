
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER(PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
),
PromotionDetails AS (
    SELECT 
        p.p_promo_id,
        p.p_promo_name,
        COUNT(CASE WHEN ws.ws_order_number IS NOT NULL THEN 1 END) AS promo_sales_count
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id, p.p_promo_name
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_income_band_sk,
        COUNT(DISTINCT s.ss_ticket_number) AS total_store_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_income_band_sk
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_income_band_sk,
    SUM(scte.ws_net_profit) AS total_net_profit,
    SUM(pid.promo_sales_count) AS total_promo_sales,
    COUNT(DISTINCT ci.total_store_sales) AS unique_store_sales
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesCTE scte ON ci.c_customer_id = scte.ws_order_number
LEFT JOIN 
    PromotionDetails pid ON scte.ws_item_sk = pid.p_promo_id
WHERE 
    ci.cd_income_band_sk IS NOT NULL
GROUP BY 
    ci.c_customer_id, ci.cd_gender, ci.cd_income_band_sk
HAVING 
    SUM(scte.ws_net_profit) > 1000 OR COUNT(DISTINCT ci.total_store_sales) > 5
ORDER BY 
    total_net_profit DESC, ci.c_customer_id ASC;
