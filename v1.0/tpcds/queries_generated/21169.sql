
WITH TotalSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_bill_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        t.total_profit,
        t.order_count,
        t.avg_sales_price
    FROM 
        customer c 
    JOIN 
        TotalSales t ON c.c_customer_sk = t.ws_bill_customer_sk
    WHERE 
        t.total_profit > (SELECT AVG(total_profit) FROM TotalSales) 
        AND c.c_current_cdemo_sk IS NOT NULL
),
PromotionAnalysis AS (
    SELECT 
        p.p_promo_name,
        COUNT(DISTINCT ws_order_number) AS promo_usage_count,
        SUM(ws_net_paid) AS total_revenue
    FROM 
        web_sales ws 
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        p.p_promo_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer_demographics cd 
    LEFT JOIN 
        web_sales ws ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status
)
SELECT 
    c.c_customer_id,
    coalesce(cd.total_quantity, 0) AS quantity_purchased,
    coalesce(cd.total_profit, 0) AS profit_generated,
    hvc.order_count,
    hvc.avg_sales_price,
    pa.promo_usage_count,
    pa.total_revenue
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    CustomerDemographics cd ON cd.cd_demo_sk = hvc.ws_bill_customer_sk
LEFT JOIN 
    PromotionAnalysis pa ON pa.promo_usage_count > 0
WHERE 
    hvc.order_count > 5 
    AND (quantity_purchased > 10 OR profit_generated > 100)
ORDER BY 
    profit_generated DESC,
    avg_sales_price ASC
LIMIT 100
OFFSET (SELECT COUNT(*) / 2 FROM HighValueCustomers);
