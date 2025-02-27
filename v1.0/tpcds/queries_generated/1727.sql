
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_paid > 100
),
TotalSales AS (
    SELECT 
        s.ws_item_sk,
        SUM(s.ws_quantity) AS total_quantity,
        SUM(s.ws_net_profit) AS total_profit
    FROM 
        web_sales s
    WHERE 
        s.ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        s.ws_item_sk
),
PromotionsWithSales AS (
    SELECT 
        p.promo_id,
        p.promo_name,
        COUNT(ws.ws_order_number) AS sales_count,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit
    FROM 
        promotion p 
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.promo_id, p.promo_name
)
SELECT 
    a.ca_city,
    a.ca_state,
    COALESCE(p.promo_name, 'No Promotion') AS promo_name,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    SUM(ts.total_profit) AS total_profit,
    SUM(ts.total_quantity) AS total_quantity,
    AVG(r.rank) AS avg_rank
FROM 
    customer_address a
LEFT JOIN 
    customer c ON a.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    TotalSales ts ON ts.ws_item_sk IN (SELECT DISTINCT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk)
LEFT JOIN 
    PromotionsWithSales p ON p.sales_count > 100
LEFT JOIN 
    RankedSales r ON r.ws_item_sk = ts.ws_item_sk
GROUP BY 
    a.ca_city, a.ca_state, promo_name
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 5
ORDER BY 
    total_profit DESC, customer_count DESC;
