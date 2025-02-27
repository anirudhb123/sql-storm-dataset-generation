
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
PromotionSales AS (
    SELECT 
        p.p_promo_sk,
        SUM(ws_ext_sales_price) AS promo_sales
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        p.p_promo_sk
)
SELECT 
    ca.city, 
    ca.state,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(sh.total_sales, 0) AS total_sales,
    COALESCE(sh.total_orders, 0) AS total_orders,
    COALESCE(ps.promo_sales, 0) AS promo_sales,
    (SELECT COUNT(*) 
     FROM web_sales ws2 
     WHERE ws2.ws_bill_customer_sk = c.c_customer_sk 
     AND ws2.ws_sold_date_sk BETWEEN 24796 AND 25000) AS sales_last_30_days,
    ROW_NUMBER() OVER (ORDER BY COALESCE(sh.total_sales, 0) DESC) AS overall_rank
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    SalesHierarchy sh ON sh.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN 
    PromotionSales ps ON ps.p_promo_sk = c.c_current_cdemo_sk -- Example of using a promo key to relate to sales
WHERE 
    (cd.cd_marital_status IS NOT NULL OR cd.cd_gender IS NOT NULL)
    AND (ca.state IS NOT NULL OR ca.city IS NOT NULL)
    AND (sh.total_sales > 1000 OR ps.promo_sales < 500)
ORDER BY 
    overall_rank;
