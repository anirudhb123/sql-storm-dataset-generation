
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_net_profit) AS total_profit,
        w.w_warehouse_id,
        dar.d_date AS sales_date
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim dar ON ws.ws_sold_date_sk = dar.d_date_sk
    WHERE 
        dar.d_year = 2023
    GROUP BY 
        ws_item_sk, w.w_warehouse_id, dar.d_date
),
RankedSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.w_warehouse_id,
        sd.sales_date,
        sd.total_profit,
        RANK() OVER (PARTITION BY sd.w_warehouse_id ORDER BY sd.total_profit DESC) AS profit_rank
    FROM 
        SalesData sd
)
SELECT 
    r.ws_item_sk,
    r.w_warehouse_id,
    r.total_profit,
    r.sales_date,
    COALESCE(AVG(r.total_profit) OVER (PARTITION BY r.w_warehouse_id), 0) AS avg_profit,
    CASE 
        WHEN r.profit_rank <= 5 THEN 'Top Seller'
        ELSE 'Regular Sales'
    END AS sale_category
FROM 
    RankedSales r
LEFT JOIN 
    customer_demographics cd ON cd.cd_demo_sk = (
        SELECT 
            c.c_current_cdemo_sk 
        FROM 
            customer c 
        WHERE 
            c.c_customer_sk IN (
                SELECT 
                    DISTINCT ws_bill_customer_sk 
                FROM 
                    web_sales 
                WHERE 
                    ws_item_sk = r.ws_item_sk
            )
    )
WHERE 
    (cd.cd_gender IS NULL OR cd.cd_gender = 'M')
    AND r.total_profit > (SELECT AVG(total_profit) FROM RankedSales)
ORDER BY 
    r.total_profit DESC, r.sales_date ASC
LIMIT 10 OFFSET 2;
