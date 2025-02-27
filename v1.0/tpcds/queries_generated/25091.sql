
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.education_status,
        cd.gender,
        c.c_birth_year,
        ROW_NUMBER() OVER (PARTITION BY cd.education_status ORDER BY c.c_birth_year DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.education_status IS NOT NULL
),
RecentReturns AS (
    SELECT 
        sr.returned_date_sk,
        COUNT(sr.return_quantity) AS total_returns,
        SUM(sr.return_amt) AS total_return_value
    FROM 
        store_returns sr
    JOIN 
        date_dim d ON sr.returned_date_sk = d.d_date_sk
    WHERE 
        d.d_date > CURRENT_DATE - INTERVAL '1 YEAR'
    GROUP BY 
        sr.returned_date_sk
),
PromotionUsage AS (
    SELECT 
        pr.p_promo_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        promotion pr
    JOIN 
        web_sales ws ON pr.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        pr.p_promo_id
)
SELECT 
    rc.full_name,
    rc.education_status,
    rc.gender,
    rc.c_birth_year,
    rr.returned_date_sk,
    rr.total_returns,
    rr.total_return_value,
    pu.p_promo_id,
    pu.total_orders,
    pu.total_profit
FROM 
    RankedCustomers rc
LEFT JOIN 
    RecentReturns rr ON rc.c_customer_sk = rr.returned_date_sk
LEFT JOIN 
    PromotionUsage pu ON rc.full_name LIKE '%' || pu.p_promo_id || '%'
WHERE 
    rc.rank <= 10
ORDER BY 
    rc.education_status, rc.c_birth_year DESC;
