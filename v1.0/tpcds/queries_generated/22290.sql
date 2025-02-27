
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws_item_sk,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY ws_sales_price DESC) AS SalesRank,
        COALESCE(SUM(ws_ext_discount_amt) OVER (PARTITION BY ws.web_site_id ORDER BY ws_sales_price DESC ROWS BETWEEN 1 PRECEDING AND CURRENT ROW), 0) AS RunningDiscount
    FROM 
        web_sales ws
),
CustomerInfo AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS GenderRank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
HighValueCustomers AS (
    SELECT 
        ci.c_customer_id,
        COUNT(ws.ws_item_sk) AS TotalPurchases
    FROM 
        CustomerInfo ci
    JOIN 
        web_sales ws ON ci.c_customer_id = ws.ws_bill_customer_sk
    GROUP BY 
        ci.c_customer_id
    HAVING 
        COUNT(ws.ws_item_sk) > 5
),
PromotionsUsed AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS PromoUsageCount
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
    HAVING 
        COUNT(DISTINCT ws.ws_order_number) > 2
)
SELECT 
    r.web_site_id,
    COUNT(DISTINCT hvc.c_customer_id) AS HighValueCustomerCount,
    SUM(rs.RunningDiscount) AS TotalDiscounts,
    STRING_AGG(DISTINCT pu.p_promo_id) AS UsedPromotions
FROM 
    RankedSales rs
JOIN 
    HighValueCustomers hvc ON rs.ws_item_sk = hvc.c_customer_id
JOIN 
    PromotionsUsed pu ON pu.PromoUsageCount > 0
LEFT JOIN 
    date_dim dd ON dd.d_date_sk = rs.ws_sold_date_sk
WHERE 
    (dd.d_year = 2023 OR dd.d_year IS NULL) AND
    (rs.SalesRank <= 10 OR rs.ws_sales_price IS NULL)
GROUP BY 
    r.web_site_id
HAVING 
    COUNT(DISTINCT hvc.c_customer_id) > 0
ORDER BY 
    HighValueCustomerCount DESC, TotalDiscounts DESC;
