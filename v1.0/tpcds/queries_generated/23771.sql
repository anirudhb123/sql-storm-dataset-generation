
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_sales_price) DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
), high_value_customers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.order_count,
        CASE 
            WHEN cs.order_count IS NULL THEN 'No Orders' 
            WHEN cs.total_sales IS NULL THEN 'No Sales'
            WHEN cs.total_sales > 1000 THEN 'High Value'
            ELSE 'Regular' 
        END AS customer_segment
    FROM 
        customer_sales cs
    WHERE 
        cs.rn = 1
), daily_sales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_sales_price) AS daily_total_sales
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date
)
SELECT 
    hvc.c_customer_id,
    hvc.total_sales,
    hvc.customer_segment,
    ds.daily_total_sales,
    CASE 
        WHEN hvc.customer_segment = 'High Value' THEN 'Flagged'
        ELSE NULL
    END AS customer_flag,
    (SELECT COUNT(*) 
     FROM store_sales ss 
     WHERE ss.ss_item_sk IN (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = hvc.c_customer_id)
    ) AS items_purchased,
    COALESCE(ds.daily_total_sales / NULLIF(hvc.total_sales, 0), 0) AS sales_ratio
FROM 
    high_value_customers hvc
FULL OUTER JOIN 
    daily_sales ds ON ds.daily_total_sales > 1000
WHERE 
    hvc.total_sales IS NOT NULL 
    AND hvc.customer_segment != 'No Orders'
ORDER BY 
    hvc.total_sales DESC,
    ds.daily_total_sales DESC
LIMIT 100;
