
WITH RECURSIVE TopSellingItems AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        RANK() OVER (ORDER BY SUM(ws_quantity) DESC) AS item_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_quantity) > 100
), 
CustomerPromotions AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT p.p_promo_sk) AS promo_count,
        AVG(p.p_cost) AS avg_promotion_cost
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        c.c_customer_sk
), 
HighValueCustomers AS (
    SELECT 
        cd.cd_gender,
        CASE 
            WHEN cd.cd_purchase_estimate >= 1000 THEN 'High Value'
            WHEN cd.cd_purchase_estimate >= 500 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_gender, customer_value
), 
TopShippingCosts AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_ext_ship_cost) AS total_shipping_cost
    FROM 
        web_sales ws
    JOIN 
        TopSellingItems tsi ON ws.ws_item_sk = tsi.ws_item_sk
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    hv.customer_value,
    hv.cd_gender,
    SUM(cp.promo_count) AS total_promotions,
    SUM(tsc.total_shipping_cost) AS total_shipping_cost
FROM 
    HighValueCustomers hv
LEFT JOIN 
    CustomerPromotions cp ON hv.c_customer_sk = cp.c_customer_sk
LEFT JOIN 
    TopShippingCosts tsc ON hv.c_customer_sk = tsc.ws_item_sk
GROUP BY 
    hv.customer_value, hv.cd_gender
HAVING 
    SUM(cp.promo_count) > 0 OR SUM(tsc.total_shipping_cost) > 0
ORDER BY 
    customer_value DESC, total_promotions DESC;
