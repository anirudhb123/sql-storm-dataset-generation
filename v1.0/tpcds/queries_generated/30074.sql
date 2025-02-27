
WITH RECURSIVE cte_customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(cs.cs_sales_price), 0) + cs.total_sales
    FROM 
        cte_customer_sales cs
    JOIN 
        catalog_sales cs2 ON cs.c_customer_sk = cs2.cs_ship_customer_sk
    POST JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs2.cs_item_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        total_sales,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        cte_customer_sales
)
SELECT 
    ss.c_customer_sk,
    ss.c_first_name,
    ss.c_last_name,
    CASE 
        WHEN ss.total_sales IS NULL THEN 'No Sales'
        WHEN ss.total_sales < 100 THEN 'Low Sales'
        WHEN ss.total_sales BETWEEN 100 AND 500 THEN 'Medium Sales'
        ELSE 'High Sales'
    END AS sales_category,
    COALESCE(cc.cc_name, 'Unknown') AS call_center_name,
    ARRAY_AGG(DISTINCT wr.wr_item_sk) AS returned_items,
    NULLIF(MAX(cs.cs_net_profit), 0) AS max_net_profit
FROM 
    sales_summary ss
LEFT JOIN 
    call_center cc ON cc.cc_call_center_sk = ss.c_customer_sk % 10
LEFT JOIN 
    web_returns wr ON wr.wr_returned_date_sk = CURRENT_DATE
LEFT JOIN 
    catalog_sales cs ON cs.cs_ship_customer_sk = ss.c_customer_sk
WHERE 
    ss.sales_rank <= 10
GROUP BY 
    ss.c_customer_sk, ss.c_first_name, ss.c_last_name, ss.total_sales, cc.cc_name
ORDER BY 
    ss.total_sales DESC;
