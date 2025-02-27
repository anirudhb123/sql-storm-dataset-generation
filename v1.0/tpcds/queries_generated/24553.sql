
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2400 AND 2500
), 
TopProfitableItems AS (
    SELECT 
        rs.ws_item_sk,
        SUM(ws_net_profit) AS total_profit
    FROM 
        RankedSales rs
    JOIN 
        web_sales ws ON rs.ws_item_sk = ws.ws_item_sk
    WHERE 
        rs.rank <= 5
    GROUP BY 
        rs.ws_item_sk
), 
CustomerAnalysis AS (
    SELECT 
        c.c_customer_id,
        SUM(ws_net_profit) AS customer_profit,
        COUNT(DISTINCT ws_order_number) AS orders_count,
        AVG(ws_net_paid) AS avg_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
    HAVING 
        customer_profit IS NOT NULL 
        AND AVG(ws_net_paid) > (SELECT AVG(ws_net_paid) FROM web_sales)
), 
FinalReport AS (
    SELECT 
        ca.c_customer_id,
        ipa.total_profit,
        ca.customer_profit,
        CASE 
            WHEN ca.orders_count > 0 THEN ca.customer_profit / ca.orders_count 
            ELSE 0 
        END AS avg_profit_per_order
    FROM 
        CustomerAnalysis ca
    JOIN 
        TopProfitableItems ipa ON ipa.ws_item_sk IN (
            SELECT 
                ws_item_sk 
            FROM 
                web_sales 
            WHERE 
                ws_sold_date_sk > 2500
        )
)
SELECT 
    fr.c_customer_id,
    COALESCE(fr.total_profit, 0) AS top_item_profit,
    fr.customer_profit,
    fr.avg_profit_per_order
FROM 
    FinalReport fr
WHERE 
    fr.avg_profit_per_order > 20
ORDER BY 
    fr.customer_profit DESC, 
    fr.avg_profit_per_order ASC;
