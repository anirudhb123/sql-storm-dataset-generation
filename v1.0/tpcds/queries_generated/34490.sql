
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ss_item_sk,
        ss_sales_price,
        ss_quantity,
        ss_net_profit,
        1 AS level
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk = (SELECT max(ss_sold_date_sk) FROM store_sales)
    
    UNION ALL
    
    SELECT 
        s.ss_item_sk,
        s.ss_sales_price * 0.9 AS ss_sales_price, 
        s.ss_quantity * 1.1 AS ss_quantity,
        s.ss_net_profit * 1.05 AS ss_net_profit,
        cte.level + 1
    FROM 
        store_sales s
    JOIN 
        SalesCTE cte ON s.ss_item_sk = cte.ss_item_sk
    WHERE 
        cte.level < 5
),
AggregatedSales AS (
    SELECT 
        i.i_item_id,
        SUM(ss_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_net_profit
    FROM 
        SalesCTE sc
    JOIN 
        item i ON sc.ss_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id
),
MaxSales AS (
    SELECT 
        total_sales,
        total_quantity,
        total_net_profit
    FROM 
        AggregatedSales
    ORDER BY 
        total_sales DESC
    LIMIT 10
)
SELECT 
    ma.total_sales,
    ma.total_quantity,
    ma.total_net_profit,
    CASE 
        WHEN ma.total_net_profit IS NULL THEN 'No Profit'
        ELSE 'Profit Exists'
    END AS profit_status,
    COALESCE(CONCAT('Sales: ', CAST(ma.total_sales AS VARCHAR), ' | Quantity: ', CAST(ma.total_quantity AS VARCHAR)), 'No Sales Data') AS sales_info,
    ROW_NUMBER() OVER (ORDER BY ma.total_sales DESC) AS rank
FROM 
    MaxSales ma
ORDER BY 
    ma.total_sales DESC;
