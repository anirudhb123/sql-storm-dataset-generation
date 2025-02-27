
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        ws_item_sk
), 
SalesWithPromotion AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity_sold,
        r.total_net_paid,
        COALESCE(p.p_promo_id, 'No Promo') AS promo_id
    FROM 
        RankedSales r
    LEFT JOIN 
        promotion p ON r.ws_item_sk = p.p_item_sk
    WHERE 
        r.rn = 1
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        ib.ib_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        cd.cd_gender, ib.ib_income_band_sk
)
SELECT 
    s.promo_id,
    SUM(s.total_quantity_sold) AS total_sold,
    SUM(s.total_net_paid) AS total_revenue,
    dc.cd_gender,
    dc.ib_income_band_sk,
    COALESCE(dc.customer_count, 0) AS demographics_count
FROM 
    SalesWithPromotion s
LEFT JOIN 
    CustomerDemographics dc ON s.ws_item_sk = dc.ib_income_band_sk
GROUP BY 
    s.promo_id, dc.cd_gender, dc.ib_income_band_sk
ORDER BY 
    total_revenue DESC;
