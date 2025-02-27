
WITH RankedReturns AS (
    SELECT 
        sr.returning_customer_sk,
        sr.returning_cdemo_sk,
        sr.return_item_sk,
        ROW_NUMBER() OVER (PARTITION BY sr.return_item_sk ORDER BY sr.return_date_sk DESC) AS rn
    FROM 
        store_returns sr
    WHERE 
        sr.return_quantity > 0
),
SalesStats AS (
    SELECT 
        ws.ship_customer_sk,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(ws.order_number) AS total_orders,
        AVG(ws.net_paid) AS avg_net_paid
    FROM 
        web_sales ws
    WHERE 
        ws.ship_date_sk IS NOT NULL
    GROUP BY 
        ws.ship_customer_sk
),
FilterPromotions AS (
    SELECT 
        p.promo_id,
        p.cost,
        p.promo_name,
        p.discount_active
    FROM 
        promotion p
    WHERE 
        p.discount_active = 'Y'
        AND EXISTS (
            SELECT 1
            FROM store_sales ss
            WHERE ss.promo_sk = p.promo_sk
            HAVING SUM(ss.net_paid) > 1000
        )
)
SELECT 
    c.first_name,
    c.last_name,
    ca.city,
    ds.d_date,
    COALESCE(s.total_net_profit, 0) AS net_profit,
    COALESCE(r.rn, 0) AS return_rank,
    pp.promo_name
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    SalesStats s ON c.c_customer_sk = s.ship_customer_sk
LEFT JOIN 
    RankedReturns r ON c.c_customer_sk = r.returning_customer_sk AND r.rn = 1
LEFT JOIN 
    FilterPromotions pp ON pp.promo_id = (
        SELECT 
            p.promo_id
        FROM 
            promotion p
        WHERE 
            p.promo_sk = (
                SELECT 
                    ws.promo_sk
                FROM 
                    web_sales ws
                WHERE 
                    ws.bill_customer_sk = c.c_customer_sk
                ORDER BY 
                    ws.sold_date_sk DESC 
                LIMIT 1
            )
        LIMIT 1
    )
CROSS JOIN 
    date_dim ds
WHERE 
    ds.d_date = CURRENT_DATE - INTERVAL '1 DAY'
ORDER BY 
    net_profit DESC, 
    return_rank ASC;
