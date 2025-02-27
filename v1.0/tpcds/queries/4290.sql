
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
    WHERE 
        total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
    JOIN 
        HighValueCustomers hvc ON cd.cd_demo_sk = hvc.c_customer_sk
),
PromotionCounts AS (
    SELECT 
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS usage_count
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_name
),
TopPromotions AS (
    SELECT 
        p.p_promo_name,
        usage_count,
        RANK() OVER (ORDER BY usage_count DESC) AS promo_rank
    FROM 
        PromotionCounts p
    WHERE 
        usage_count > (SELECT AVG(usage_count) FROM PromotionCounts)
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    tp.p_promo_name,
    tp.usage_count
FROM 
    HighValueCustomers hvc
JOIN 
    CustomerDemographics cd ON hvc.c_customer_sk = cd.cd_demo_sk
LEFT JOIN 
    TopPromotions tp ON hvc.c_customer_sk IN (
        SELECT 
            ws_bill_customer_sk 
        FROM 
            web_sales 
        WHERE 
            ws_promo_sk IN (SELECT p_promo_sk FROM promotion WHERE p_promo_name = tp.p_promo_name)
    )
WHERE 
    hvc.sales_rank <= 10
ORDER BY 
    hvc.total_sales DESC,
    tp.usage_count DESC;
