
WITH RecursiveSales AS (
    SELECT 
        ws_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_customer_sk
), 
TopCustomers AS (
    SELECT 
        cs_ship_customer_sk,
        SUM(cs_net_profit) AS total_profit,
        SUM(cs_quantity) AS total_quantity,
        COUNT(cs_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(cs_net_profit) DESC) AS profit_rank
    FROM 
        catalog_sales
    GROUP BY 
        cs_ship_customer_sk
),
CombinedSales AS (
    SELECT 
        c.c_customer_id,
        COALESCE(r.total_net_profit, 0) AS web_profit,
        COALESCE(t.total_profit, 0) AS catalog_profit,
        COALESCE(t.order_count, 0) AS catalog_orders,
        COALESCE(r.order_count, 0) AS web_orders,
        CASE 
            WHEN COALESCE(r.total_net_profit, 0) > COALESCE(t.total_profit, 0) THEN 'Web'
            WHEN COALESCE(r.total_net_profit, 0) < COALESCE(t.total_profit, 0) THEN 'Catalog'
            ELSE 'Equal'
        END AS dominant_channel
    FROM 
        customer c
    LEFT JOIN 
        RecursiveSales r ON c.c_customer_sk = r.ws_customer_sk 
    LEFT JOIN 
        TopCustomers t ON c.c_customer_sk = t.cs_ship_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    CONCAT('Profit via Web: ', web_profit, ', Catalog: ', catalog_profit, ' | Orders - Web: ', web_orders, ', Catalog: ', catalog_orders) AS sales_summary,
    COUNT(CASE WHEN dominant_channel = 'Web' THEN 1 END) AS web_dominance_count,
    COUNT(CASE WHEN dominant_channel = 'Catalog' THEN 1 END) AS catalog_dominance_count,
    COUNT(CASE WHEN dominant_channel = 'Equal' THEN 1 END) AS equal_count
FROM 
    CombinedSales c
WHERE 
    (web_profit > 0 OR catalog_profit > 0)
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, web_profit, catalog_profit, web_orders, catalog_orders
HAVING 
    (SUM(web_profit + catalog_profit) > 1000 OR COUNT(DISTINCT CASE WHEN dominant_channel = 'Web' THEN c.c_customer_id ELSE NULL END) > 5)
ORDER BY 
    web_profit - catalog_profit DESC, order_count DESC;
