
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number,
        ws.ws_quantity,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number) AS cumulative_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 0
        AND ws.ws_quantity IS NOT NULL
),
TopItems AS (
    SELECT 
        rs.ws_item_sk,
        COUNT(rs.ws_order_number) AS order_count,
        AVG(rs.cumulative_profit) AS avg_cumulative_profit
    FROM 
        RankedSales rs
    GROUP BY 
        rs.ws_item_sk
    HAVING 
        COUNT(rs.ws_order_number) > 10
        AND AVG(rs.cumulative_profit) > 1000
),
CustomerReturns AS (
    SELECT 
        sr_returning_customer_sk,
        COUNT(cr_return_number) AS return_count,
        SUM(cr_return_amount) AS total_return_amount 
    FROM 
        catalog_returns cr
    WHERE 
        cr_return_quantity > 0
    GROUP BY 
        sr_returning_customer_sk
),
FinalReport AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ti.order_count,
        ci.c_birth_month,
        COALESCE(cr.total_return_amount, 0) AS total_returns,
        CASE 
            WHEN ti.order_count IS NULL THEN 'No Orders'
            WHEN cr.total_return_amount > 500 THEN 'High Return'
            ELSE 'Normal'
        END AS return_status
    FROM 
        customer ci
    LEFT JOIN 
        TopItems ti ON ci.c_customer_sk = ti.ws_item_sk
    LEFT JOIN 
        CustomerReturns cr ON ci.c_customer_sk = cr.sr_returning_customer_sk
)
SELECT 
    fr.c_customer_sk,
    fr.c_first_name,
    fr.c_last_name,
    fr.order_count,
    fr.c_birth_month,
    fr.total_returns,
    fr.return_status
FROM 
    FinalReport fr
WHERE 
    fr.c_birth_month = (SELECT MAX(c_birth_month) FROM customer)
ORDER BY 
    fr.total_returns DESC NULLS LAST,
    fr.return_status,
    fr.c_first_name;
