
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_quantity) AS total_quantity,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 10.00
        AND ws.ws_sold_date_sk IN (SELECT d.d_date_sk 
                                    FROM date_dim d 
                                    WHERE d.d_year = 2023)
    GROUP BY 
        ws.web_site_id
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT CASE WHEN ws.ws_bill_customer_sk IS NOT NULL THEN ws.ws_order_number END) AS order_count,
        SUM(COALESCE(ws.ws_net_paid_inc_tax, 0)) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_id
),
FinalMetrics AS (
    SELECT 
        sd.web_site_id,
        sd.total_sales,
        sd.order_count,
        cs.order_count AS customer_order_count,
        cs.total_spent,
        sr.sales_rank
    FROM 
        SalesData sd
    LEFT JOIN 
        CustomerStats cs ON cs.order_count > 0
    JOIN 
        (SELECT DISTINCT ws_site_id, sales_rank FROM SalesData) sr 
    ON 
        sr.sales_rank = sd.sales_rank
    WHERE 
        cs.total_spent > 1000
)
SELECT 
    f.web_site_id,
    f.total_sales,
    f.order_count,
    COALESCE(f.customer_order_count, 0) AS customer_order_count,
    ROUND(f.total_spent, 2) AS total_spent,
    CASE 
        WHEN f.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status
FROM 
    FinalMetrics f
ORDER BY 
    f.total_sales DESC;
