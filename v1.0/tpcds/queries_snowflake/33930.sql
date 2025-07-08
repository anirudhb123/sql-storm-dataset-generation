
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        1 AS depth
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    
    UNION ALL
    
    SELECT 
        cs_order_number,
        cs_item_sk,
        cs_sales_price,
        cs_quantity,
        cs_net_profit,
        depth + 1
    FROM 
        catalog_sales cs 
    JOIN 
        SalesData sd ON cs_order_number = sd.ws_order_number
    WHERE 
        depth < 5
),
RankedSales AS (
    SELECT 
        sd.ws_order_number,
        sd.ws_item_sk,
        sd.ws_sales_price,
        sd.ws_quantity,
        sd.ws_net_profit,
        RANK() OVER (PARTITION BY sd.ws_order_number ORDER BY sd.ws_net_profit DESC) AS profit_rank
    FROM 
        SalesData sd
),
FinalResults AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        SUM(rs.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT rs.ws_order_number) AS order_count,
        AVG(rs.ws_sales_price) AS avg_sales_price
    FROM 
        customer c
    JOIN 
        RankedSales rs ON rs.ws_item_sk = c.c_customer_sk
    GROUP BY 
        c.c_first_name, c.c_last_name
)
SELECT 
    fr.c_first_name,
    fr.c_last_name,
    fr.total_net_profit,
    fr.order_count,
    fr.avg_sales_price
FROM 
    FinalResults fr
WHERE 
    fr.total_net_profit > (
        SELECT 
            AVG(total_net_profit) 
        FROM 
            FinalResults
    )
ORDER BY 
    fr.total_net_profit DESC
LIMIT 10;
