
WITH SalesData AS (
    SELECT 
        w.warehouse_name,
        SUM(ws.net_profit) AS total_profit,
        AVG(ws.net_paid_inc_tax) AS avg_net_paid,
        COUNT(DISTINCT cs.order_number) AS total_orders,
        MAX(ws.sales_price) AS max_sales_price,
        MIN(ws.sales_price) AS min_sales_price
    FROM 
        store_sales ss
    JOIN 
        warehouse w ON ss.store_sk = w.warehouse_sk
    JOIN 
        web_sales ws ON ss.item_sk = ws.item_sk
    JOIN 
        catalog_sales cs ON ss.item_sk = cs.item_sk
    WHERE 
        w.warehouse_state = 'CA' 
        AND ws.sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY 
        w.warehouse_name
), 
RankedSales AS (
    SELECT 
        warehouse_name,
        total_profit,
        avg_net_paid,
        total_orders,
        max_sales_price,
        min_sales_price,
        RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
    FROM 
        SalesData
)
SELECT 
    rs.warehouse_name,
    rs.total_profit,
    rs.avg_net_paid,
    rs.total_orders,
    rs.max_sales_price,
    rs.min_sales_price,
    CASE 
        WHEN rs.total_orders > 100 THEN 'High Order Volume'
        WHEN rs.total_orders BETWEEN 50 AND 100 THEN 'Medium Order Volume'
        ELSE 'Low Order Volume'
    END AS order_volume,
    (SELECT COUNT(*) 
     FROM customer c 
     WHERE c.current_cdemo_sk IN 
        (SELECT cd_demo_sk 
         FROM customer_demographics 
         WHERE cd_marital_status = 'M' AND cd_gender = 'F') 
     AND c.current_addr_sk IS NOT NULL
    ) AS married_female_customers
FROM 
    RankedSales rs
WHERE 
    rs.profit_rank <= 5;
