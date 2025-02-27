
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
HighSpenders AS (
    SELECT 
        r.c_customer_id,
        r.total_net_paid,
        CASE 
            WHEN r.rank <= 10 THEN 'Top 10 %' 
            ELSE 'Other' 
        END AS customer_category
    FROM 
        RankedCustomers r
    WHERE 
        r.total_net_paid IS NOT NULL
),
Promotions AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS promo_sales_count
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
)
SELECT 
    h.c_customer_id,
    h.total_net_paid,
    COALESCE(pm.promo_sales_count, 0) AS promo_count,
    CASE 
        WHEN h.total_net_paid IS NULL THEN 'No Sales'
        WHEN h.total_net_paid > 1000 THEN 'Heavy Spender'
        ELSE 'Regular Spender'
    END AS spending_category
FROM 
    HighSpenders h
LEFT JOIN 
    Promotions pm ON h.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_customer_sk = h.c_customer_id)
WHERE 
    h.total_net_paid > (SELECT AVG(total_net_paid) FROM HighSpenders)
ORDER BY 
    h.total_net_paid DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
