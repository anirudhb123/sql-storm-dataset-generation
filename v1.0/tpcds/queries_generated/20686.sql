
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank,
        CASE 
            WHEN SUM(ws.ws_net_profit) IS NULL THEN 'UNKNOWN'
            ELSE 'KNOWN'
        END AS profit_status
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
    HAVING 
        SUM(ws.ws_net_profit) > 0
),
RankedSales AS (
    SELECT
        sh.c_customer_id,
        sh.total_net_profit,
        sh.rank,
        COALESCE((SELECT COUNT(*) FROM SalesHierarchy h WHERE h.total_net_profit > sh.total_net_profit), 0) AS rank_position,
        CASE 
            WHEN sh.total_net_profit > 1000 THEN 'HIGH'
            WHEN sh.total_net_profit BETWEEN 500 AND 1000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category
    FROM 
        SalesHierarchy sh
)
SELECT 
    ss.c_customer_id,
    SUM(ws.ws_sales_price - ws.ws_ext_discount_amt) AS adjusted_sales_price,
    MAX(ws.ws_ship_date_sk) AS last_ship_date,
    COALESCE(SUM(ws.ws_net_paid_inc_tax), 0) AS total_amount_paid,
    STRING_AGG(DISTINCT ia.i_item_desc) AS items_purchased
FROM 
    RankedSales rs
JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = rs.c_customer_id
JOIN 
    item ia ON ws.ws_item_sk = ia.i_item_sk
LEFT JOIN 
    store s ON s.s_store_sk = (SELECT ss_store_sk FROM store_sales ss WHERE ss.ss_item_sk = ws.ws_item_sk ORDER BY ss.ss_net_profit DESC LIMIT 1)
WHERE 
    rs.rank_position < 5
GROUP BY 
    ss.c_customer_id
HAVING 
    SUM(ws.ws_sales_price) > 500
ORDER BY 
    adjusted_sales_price DESC
LIMIT 10
OFFSET 0;
