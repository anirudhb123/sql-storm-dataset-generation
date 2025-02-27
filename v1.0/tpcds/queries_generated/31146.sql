
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        ss_store_sk, 
        ss_item_sk, 
        SUM(ss_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_profit) DESC) AS rnk
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk, 
        ss_item_sk
), 
HighPerformingStores AS (
    SELECT 
        sh.ss_store_sk,
        sh.total_net_profit,
        s.s_store_name,
        s.s_city,
        s.s_state
    FROM 
        SalesHierarchy sh
    JOIN 
        store s ON sh.ss_store_sk = s.s_store_sk
    WHERE 
        sh.rnk <= 5
), 
CustomerInsights AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        SUM(ws.ws_net_paid) AS total_web_spent,
        SUM(cs.cs_net_paid) AS total_catalog_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
), 
Promotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        SUM(ws.ws_ext_discount_amt) AS total_discount_given
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk, 
        p.p_promo_name
)
SELECT 
    hps.ss_store_sk, 
    hps.s_store_name, 
    hps.total_net_profit,
    ci.c_customer_sk, 
    ci.c_first_name, 
    ci.c_last_name,
    pi.promo_name,
    pi.total_discount_given
FROM 
    HighPerformingStores hps
LEFT JOIN 
    CustomerInsights ci ON hps.ss_store_sk IN (
        SELECT s_store_sk 
        FROM store_sales 
        WHERE ss_net_profit > 0
    )
LEFT JOIN 
    Promotions pi ON pi.total_discount_given IS NOT NULL
WHERE 
    hps.total_net_profit > (
        SELECT AVG(total_net_profit) 
        FROM HighPerformingStores
    )
ORDER BY 
    hps.total_net_profit DESC, 
    ci.total_web_spent DESC;
