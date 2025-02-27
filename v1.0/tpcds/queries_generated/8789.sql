
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        ws.web_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_profit,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers
    FROM 
        web_sales ws
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        w.web_close_date_sk IS NULL
        AND EXISTS (
            SELECT 1 
            FROM store_returns sr 
            WHERE sr.sr_customer_sk = c.c_customer_sk 
              AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2450600
        )
    GROUP BY 
        ws.web_site_id, ws.web_name
),
RankedSales AS (
    SELECT 
        sd.web_site_id,
        sd.web_name,
        sd.total_sales,
        sd.total_orders,
        sd.avg_profit,
        sd.unique_customers,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    r.web_site_id,
    r.web_name,
    r.total_sales,
    r.total_orders,
    r.avg_profit,
    r.unique_customers,
    CASE 
        WHEN r.sales_rank <= 5 THEN 'Top Performer'
        WHEN r.sales_rank <= 10 THEN 'Mid-Performer'
        ELSE 'Under Performer'
    END AS performance_category
FROM 
    RankedSales r
WHERE 
    r.total_sales > 0
ORDER BY 
    r.total_sales DESC;
