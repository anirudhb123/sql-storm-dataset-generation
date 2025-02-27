
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_net_paid) AS total_store_sales,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transaction_count,
        COUNT(DISTINCT ws.ws_order_number) AS web_transaction_count
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
Promotions AS (
    SELECT 
        p.p_promo_sk,
        COUNT(DISTINCT cs.cs_order_number) AS promotion_order_count,
        SUM(cs.cs_net_profit) AS total_promotion_profit
    FROM 
        promotion p
    LEFT JOIN 
        catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY 
        p.p_promo_sk
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_store_sales,
        cs.total_web_sales,
        cs.store_transaction_count,
        cs.web_transaction_count,
        RANK() OVER (ORDER BY cs.total_store_sales + cs.total_web_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_store_sales IS NOT NULL OR cs.total_web_sales IS NOT NULL
    HAVING 
        (cs.total_store_sales + cs.total_web_sales) > 1000
)
SELECT 
    hvc.c_customer_sk,
    hvc.total_store_sales,
    hvc.total_web_sales,
    hvc.store_transaction_count,
    hvc.web_transaction_count,
    COALESCE(promotion_order_count, 0) AS promotion_orders,
    COALESCE(total_promotion_profit, 0.00) AS total_profit_from_promotions
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    (SELECT 
         c_customer_sk,
         SUM(promotion_order_count) AS promotion_order_count,
         SUM(total_promotion_profit) AS total_promotion_profit
     FROM 
         Promotions 
     GROUP BY 
         c_customer_sk) p
ON 
    hvc.c_customer_sk = p.c_customer_sk
WHERE 
    hvc.sales_rank <= 10
ORDER BY 
    hvc.total_store_sales + hvc.total_web_sales DESC;
