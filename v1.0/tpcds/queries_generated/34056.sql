
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        NULL::integer AS parent_customer_sk,
        0 AS level
    FROM 
        customer c
    WHERE 
        c.c_customer_sk IN (SELECT c_customer_sk FROM store_sales GROUP BY c_customer_sk HAVING SUM(ss_quantity) > 10)
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ch.c_customer_sk AS parent_customer_sk,
        ch.level + 1 AS level
    FROM 
        customer c
    JOIN 
        CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
), 
SalesDetails AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS item_rank,
        sm.sm_type,
        CASE 
            WHEN ws.ws_net_paid > 200 THEN 'High Value'
            WHEN ws.ws_net_paid BETWEEN 100 AND 200 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS value_category
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
), 
AggregateSales AS (
    SELECT 
        sd.ws_order_number,
        SUM(sd.ws_quantity) AS total_quantity,
        COUNT(DISTINCT sd.ws_item_sk) AS distinct_items,
        AVG(sd.ws_net_profit) AS average_profit
    FROM 
        SalesDetails sd
    WHERE 
        sd.item_rank <= 2
    GROUP BY 
        sd.ws_order_number
)

SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ag.ws_order_number,
    ag.total_quantity,
    ag.distinct_items,
    ag.average_profit,
    CASE 
        WHEN ag.average_profit > 500 THEN 'Top Performer'
        ELSE 'Standard Performer'
    END AS performance_category
FROM 
    CustomerHierarchy ch
JOIN 
    AggregateSales ag ON ch.c_customer_sk = ag.ws_order_number
WHERE 
    ch.level = 0
ORDER BY 
    ag.average_profit DESC;
