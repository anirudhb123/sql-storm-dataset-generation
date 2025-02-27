
WITH RecursiveSales AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        ws.web_site_sk, ws_sold_date_sk
),
TopWebsites AS (
    SELECT 
        web_site_sk, 
        SUM(total_quantity) AS quantity_sum,
        AVG(total_profit) AS avg_profit
    FROM 
        RecursiveSales
    WHERE 
        profit_rank <= 5
    GROUP BY 
        web_site_sk
),
InventoryCheck AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS stock_quantity,
        COUNT(DISTINCT inv.inv_warehouse_sk) AS warehouse_count
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
PromotionalAnalysis AS (
    SELECT 
        p.p_promo_id,
        COUNT(ws.ws_order_number) AS promo_success_count,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE 
        ws.ws_sold_date_sk < (SELECT MAX(d_date_sk) FROM date_dim) - 100
    GROUP BY 
        p.p_promo_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(cd.cd_demo_sk) AS demographic_count
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_marital_status = 'M' OR (cd.cd_income_band_sk IS NULL AND cd.cd_birth_month = 12)
    GROUP BY 
        cd.cd_gender
)
SELECT 
    w.w_warehouse_id,
    tw.quantity_sum,
    COALESCE(pa.promo_success_count, 0) AS promo_count,
    wd.cd_gender,
    wd.avg_purchase_estimate,
    CASE 
        WHEN tw.avg_profit IS NULL THEN 'No Profit'
        WHEN tw.avg_profit > 1000 THEN 'High Profit'
        ELSE 'Moderate Profit' 
    END AS profit_status
FROM 
    warehouse w
LEFT JOIN 
    TopWebsites tw ON tw.web_site_sk = w.w_warehouse_sk
LEFT JOIN 
    PromotionalAnalysis pa ON pa.total_revenue > 5000
CROSS JOIN 
    CustomerDemographics wd
WHERE 
    w.w_gmt_offset IS NOT NULL
ORDER BY 
    quantity_sum DESC, promo_count DESC
LIMIT 10;
