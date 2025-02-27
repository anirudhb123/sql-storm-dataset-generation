
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_income_band_sk,
        DENSE_RANK() OVER (PARTITION BY cd.cd_income_band_sk ORDER BY c.c_birth_year DESC) AS rank_birth_year
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    WHERE 
        cd.cd_gender IS NOT NULL
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws 
    GROUP BY 
        ws.ws_item_sk
),
Promotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_discount_active,
        COUNT(DISTINCT p.p_item_sk) AS active_items
    FROM 
        promotion p 
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        p.p_promo_sk, 
        p.p_discount_active
),
Returns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS distinct_returns
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.c_email_address,
    CASE 
        WHEN ci.rank_birth_year <= 5 THEN 'Top Customers'
        ELSE 'Regular Customers' 
    END AS customer_rank,
    sd.total_quantity,
    COALESCE(sd.avg_net_profit, 0.00) AS avg_net_profit,
    COALESCE(r.total_returns, 0) AS total_returns,
    p.active_items,
    CASE 
        WHEN r.distinct_returns IS NULL THEN 1
        ELSE 0 
    END AS null_case
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesData sd ON ci.c_customer_sk = sd.ws_item_sk
FULL OUTER JOIN 
    Returns r ON sd.ws_item_sk = r.sr_item_sk
JOIN 
    Promotions p ON r.total_returns > p.active_items
WHERE 
    r.total_returns IS NOT NULL OR p.active_items >= 1
ORDER BY 
    ci.c_last_name, 
    ci.c_first_name
OFFSET 10 ROWS FETCH NEXT 50 ROWS ONLY;
