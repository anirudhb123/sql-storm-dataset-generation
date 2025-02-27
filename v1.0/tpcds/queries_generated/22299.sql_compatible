
WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        cs_order_number, 
        cs_item_sk, 
        cs_quantity, 
        cs_net_profit, 
        1 AS level
    FROM 
        catalog_sales
    WHERE 
        cs_item_sk IS NOT NULL
    UNION ALL
    SELECT 
        c.cs_order_number, 
        c.cs_item_sk, 
        c.cs_quantity,
        c.cs_net_profit * 0.9 AS cs_net_profit, 
        oh.level + 1
    FROM 
        catalog_sales c
    JOIN 
        OrderHierarchy oh ON c.cs_order_number = oh.cs_order_number 
                         AND c.cs_item_sk <> oh.cs_item_sk
    WHERE 
        c.cs_net_profit < oh.cs_net_profit
),
AggregateResults AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs_order_number) AS order_count,
        AVG(cs_net_profit) AS avg_net_profit
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk >= (
            SELECT 
                MAX(d_date_sk) 
            FROM 
                date_dim 
            WHERE 
                d_year = (SELECT MAX(d_year) FROM date_dim)
        ) - 30
    GROUP BY 
        cs_item_sk
)
SELECT
    ca.ca_city,
    SUM(ar.total_quantity) AS aggregate_quantity,
    MAX(ar.order_count) AS max_orders,
    COALESCE(MIN(ar.avg_net_profit), 0) AS min_profit,
    CASE 
        WHEN MAX(ar.order_count) IS NULL THEN 'No Orders'
        WHEN MAX(ar.order_count) > 50 THEN 'High Activity'
        ELSE 'Low Activity'
    END AS activity_level
FROM 
    AggregateResults ar
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = (
        SELECT 
            c.c_current_addr_sk
        FROM 
            customer c 
        WHERE 
            c.c_customer_sk = (
                SELECT 
                    ws_bill_customer_sk 
                FROM 
                    web_sales 
                WHERE 
                    ws_item_sk = ar.cs_item_sk 
                LIMIT 1
            )
    )
LEFT JOIN 
    (SELECT 
        DISTINCT cs_item_sk 
     FROM 
        catalog_sales 
     WHERE 
        cs_net_profit < 0) AS NegativeProfits 
ON 
    ar.cs_item_sk = NegativeProfits.cs_item_sk
GROUP BY 
    ca.ca_city
ORDER BY 
    aggregate_quantity DESC, 
    max_orders ASC
FETCH FIRST 100 ROWS ONLY;
