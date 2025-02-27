
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        COUNT(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY COUNT(sr_return_quantity) DESC) AS rank
    FROM 
        store_returns
    WHERE 
        sr_return_quantity IS NOT NULL
    GROUP BY 
        sr_returned_date_sk, sr_item_sk
), 
HighReturnItems AS (
    SELECT 
        r1.sr_item_sk,
        r1.total_returns,
        r1.total_return_amt,
        r2.sr_returned_date_sk
    FROM 
        RankedReturns r1
    JOIN 
        RankedReturns r2 ON r1.sr_item_sk = r2.sr_item_sk AND r2.rank = 1
    WHERE 
        r1.total_returns > (SELECT AVG(total_returns) FROM RankedReturns)
), 
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        COALESCE(cd.cd_gender, 'U') AS gender,
        SUM(ws.net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender
), 
FinalStats AS (
    SELECT 
        hri.sr_item_sk,
        cs.c_customer_id,
        cs.total_profit,
        cs.total_orders,
        (cs.total_profit / NULLIF(cs.total_orders, 0)) AS average_order_value
    FROM 
        HighReturnItems hri
    JOIN 
        CustomerStats cs ON cs.total_profit IS NOT NULL
    WHERE 
        hri.total_return_amt > 100 AND 
        (cs.gender = 'M' OR cs.gender = 'F' OR cs.gender IS NULL)
)
SELECT 
    f.sr_item_sk,
    f.c_customer_id,
    f.total_profit,
    f.total_orders,
    f.average_order_value
FROM 
    FinalStats f
WHERE 
    f.average_order_value > 50 
    OR EXISTS (
        SELECT 1 
        FROM customer_address ca 
        WHERE ca.ca_city = 'New York' 
        AND f.c_customer_id LIKE '%' || ca.ca_address_id || '%'
    )
ORDER BY 
    f.total_profit DESC 
LIMIT 10;
