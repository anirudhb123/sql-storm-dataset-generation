
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.order_number,
        ws.sales_price,
        ws.ticket_number,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_month IN (SELECT DISTINCT d_month_seq FROM date_dim WHERE d_year = 2023)
    AND 
        ws.sold_date_sk BETWEEN 2459640 AND 2459660
),
Aggregated AS (
    SELECT 
        w.w_warehouse_id,
        SUM(COALESCE(rs.sales_price, 0)) AS total_sales,
        AVG(CASE WHEN rs.sales_rank <= 5 THEN rs.sales_price ELSE NULL END) AS avg_top_sales_price,
        COUNT(DISTINCT rs.ticket_number) AS unique_tickets
    FROM 
        RankedSales rs
    LEFT JOIN 
        warehouse w ON rs.web_site_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
FinalResults AS (
    SELECT 
        a.w_warehouse_id,
        a.total_sales,
        a.avg_top_sales_price,
        a.unique_tickets,
        CASE 
            WHEN a.total_sales IS NULL THEN 'No Sales'
            WHEN a.unique_tickets = 0 THEN 'No Tickets'
            ELSE 'Sales Exist'
        END AS sales_status
    FROM 
        Aggregated a
)
SELECT 
    fr.*,
    COALESCE(sub.sales_count, 0) AS subquery_sales,
    CONCAT('Warehouse: ', fr.w_warehouse_id, ' | Status: ', fr.sales_status) AS status_message
FROM 
    FinalResults fr
LEFT JOIN 
    (SELECT 
         ws.warehouse_sk, 
         COUNT(ws.order_number) AS sales_count 
     FROM 
         web_sales ws 
     WHERE 
         ws.ship_date_sk IS NOT NULL 
     GROUP BY 
         ws.warehouse_sk
    HAVING 
         COUNT(ws.order_number) > 10) sub ON fr.w_warehouse_id = sub.warehouse_sk
ORDER BY 
    fr.total_sales DESC, fr.warehouse_id DESC
LIMIT 20;
