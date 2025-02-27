
WITH ranked_sales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_ext_sales_price) DESC) AS sales_rank
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
), customer_stats AS (
    SELECT 
        c_customer_sk,
        COUNT(sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        c_customer_sk
), enriched_returns AS (
    SELECT 
        c.c_customer_sk,
        cs.total_sales,
        coalesce(cs.return_count, 0) AS return_count,
        coalesce(cs.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN cs.total_return_amount > 0 THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status
    FROM 
        customer c
    LEFT JOIN 
        customer_stats cs ON c.c_customer_sk = cs.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
)
SELECT 
    e.c_customer_sk,
    e.total_sales,
    e.return_count,
    e.total_return_amount,
    e.return_status,
    wa.w_warehouse_name,
    MAX(ws.ws_net_profit) OVER (PARTITION BY e.c_customer_sk) AS max_net_profit,
    AVG(ws.ws_net_paid) OVER (PARTITION BY e.c_customer_sk) AS avg_net_paid
FROM 
    enriched_returns e
JOIN 
    web_sales ws ON e.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    warehouse wa ON ws.ws_warehouse_sk = wa.w_warehouse_sk
WHERE 
    e.total_sales > (
        SELECT AVG(total_sales) FROM ranked_sales
    )
    AND e.return_count IS NOT NULL
ORDER BY 
    e.total_sales DESC, e.return_count ASC
FETCH FIRST 10 ROWS ONLY;
