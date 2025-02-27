
WITH cumulative_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(web.ws_net_paid, 0) + COALESCE(store.ss_net_paid, 0)) AS total_net_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(COALESCE(web.ws_net_paid, 0) + COALESCE(store.ss_net_paid, 0)) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales web ON c.c_customer_sk = web.ws_bill_customer_sk
    FULL OUTER JOIN 
        store_sales store ON c.c_customer_sk = store.ss_customer_sk
    WHERE 
        (c.c_birth_year IS NULL OR c.c_birth_year < 1980) 
        AND (c.c_preferred_cust_flag = 'Y' OR c.c_email_address IS NOT NULL)
    GROUP BY 
        c.c_customer_id
),
top_sales AS (
    SELECT 
        cs.c_customer_id,
        cs.total_net_sales,
        CASE 
            WHEN cs.sales_rank <= 10 THEN 'Top 10%'
            WHEN cs.sales_rank <= 50 THEN 'Top 50%'
            ELSE 'Bottom 50%'
        END AS sales_category
    FROM 
        cumulative_sales cs
)
SELECT 
    cs.c_customer_id,
    cs.total_net_sales,
    COALESCE(d.d_date, 'No Date') AS purchase_date,
    ts.sales_category,
    CONCAT('Total Purchase: $', ROUND(cs.total_net_sales, 2)) AS purchase_summary,
    CASE 
        WHEN cs.total_net_sales > 1000 THEN 'High Roller'
        WHEN cs.total_net_sales BETWEEN 500 AND 1000 THEN 'Moderate Spender'
        ELSE 'Budget Shopper'
    END AS spending_behavior
FROM 
    top_sales cs
LEFT JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws_ship_date_sk) FROM web_sales WHERE ws_bill_customer_sk = cs.c_customer_id)
WHERE
    (cs.sales_category = 'Top 10%' OR cs.total_net_sales IS NULL)
ORDER BY 
    cs.total_net_sales DESC
LIMIT 100;
