
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_age_group,
        cd.cd_income_band_sk,
        SUM(sd.total_profit) AS customer_total_profit
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN SalesData sd ON c.c_customer_sk = sd.ws_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_age_group, cd.cd_income_band_sk
),
PromotionSummary AS (
    SELECT 
        p.p_promo_name,
        COUNT(ws.ws_order_number) AS promo_order_count,
        SUM(ws.ws_net_paid) AS promo_net_sales,
        SUM(ws.ws_net_profit) AS promo_net_profit
    FROM 
        web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        p.p_promo_name
),
FinalData AS (
    SELECT 
        cd.cd_gender,
        cd.cd_income_band_sk,
        ps.promo_order_count,
        ps.promo_net_sales,
        ps.promo_net_profit,
        SUM(cd.customer_total_profit) AS total_customer_profit
    FROM 
        CustomerData cd
    JOIN PromotionSummary ps ON cd.cd_income_band_sk = ps.promo_order_count 
    GROUP BY 
        cd.cd_gender, cd.cd_income_band_sk, ps.promo_order_count, ps.promo_net_sales, ps.promo_net_profit
)
SELECT 
    cd_gender,
    cd_income_band_sk,
    promo_order_count,
    promo_net_sales,
    promo_net_profit,
    total_customer_profit
FROM 
    FinalData
ORDER BY 
    total_customer_profit DESC;
