
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_quantity > 0
),
SalesSummary AS (
    SELECT 
        s.ws_item_sk,
        SUM(s.ws_quantity) AS total_quantity,
        SUM(s.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT s.ws_sold_date_sk) AS sale_days
    FROM 
        web_sales s
    WHERE 
        EXISTS (SELECT 1 
                  FROM customer c 
                  WHERE c.c_customer_sk = s.ws_bill_customer_sk 
                    AND c.c_birth_month = EXTRACT(MONTH FROM CURRENT_DATE) 
                    AND c.c_birth_day = EXTRACT(DAY FROM CURRENT_DATE))
    GROUP BY 
        s.ws_item_sk
),
Promotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        COUNT(*) AS promo_usage
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    SUM(ss.total_quantity) AS total_quantity_sold,
    SUM(ss.total_sales) AS total_sales_amount,
    p.promo_name,
    COALESCE(pr.promo_usage, 0) AS promo_usage_count
FROM 
    customer c
LEFT JOIN 
    SalesSummary ss ON c.c_customer_sk = ss.ws_item_sk
LEFT JOIN 
    Promotions p ON ss.ws_item_sk = p.p_promo_sk
LEFT JOIN 
    (SELECT DISTINCT ws_item_sk, COUNT(*) AS promo_usage FROM web_sales GROUP BY ws_item_sk) pr ON ss.ws_item_sk = pr.ws_item_sk
WHERE 
    c.c_current_cdemo_sk IS NOT NULL
GROUP BY 
    c.c_customer_id, 
    customer_name, 
    p.promo_name
ORDER BY 
    total_sales_amount DESC
LIMIT 10;
