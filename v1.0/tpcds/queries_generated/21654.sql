
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS rank_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) - 30 
        AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
),
CustomerStats AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        cd.cd_gender,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        (SELECT AVG(ws.ws_sales_price) FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk) AS avg_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_email_address, cd.cd_gender, hd.hd_income_band_sk
),
ItemPromotions AS (
    SELECT 
        p.p_item_sk,
        SUM(p.p_response_target) AS promo_effectiveness
    FROM 
        promotion p
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        p.p_item_sk
),
SalesWithPromos AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COALESCE(ip.promo_effectiveness, 0) AS promo_effective,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank_sales
    FROM 
        web_sales ws
    LEFT JOIN 
        ItemPromotions ip ON ws.ws_item_sk = ip.p_item_sk
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    cs.c_customer_sk,
    r.total_quantity,
    cs.total_orders,
    cs.avg_spent,
    swp.total_sales,
    swp.promo_effective,
    CASE 
        WHEN r.rank_quantity <= 3 THEN 'Top Seller' 
        ELSE 'Regular Item' 
    END AS item_category,
    CASE 
        WHEN cs.income_band IN (1, 2) THEN 'Low Income'
        WHEN cs.income_band IN (3, 4) THEN 'Middle Income'
        ELSE 'High Income'
    END AS income_category
FROM 
    CustomerStats cs
JOIN 
    RankedSales r ON cs.c_customer_sk = r.ws_item_sk
LEFT JOIN 
    SalesWithPromos swp ON r.ws_item_sk = swp.ws_item_sk
WHERE 
    (r.total_quantity > 0 OR cs.total_orders > 0) 
    AND cs.avg_spent IS NOT NULL
ORDER BY 
    cs.total_orders DESC, r.total_quantity DESC
FETCH FIRST 10 ROWS ONLY;
