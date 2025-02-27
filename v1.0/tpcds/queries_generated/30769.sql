
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_sales
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk, ss_item_sk
    HAVING 
        SUM(ss_quantity) > 0
),
Top_Sellers AS (
    SELECT 
        s.s_store_name,
        i.i_item_desc,
        sc.total_quantity,
        RANK() OVER (PARTITION BY s.s_store_sk ORDER BY sc.total_sales DESC) AS sales_rank
    FROM 
        Sales_CTE sc
    JOIN 
        store s ON sc.ss_store_sk = s.s_store_sk
    JOIN 
        item i ON sc.ss_item_sk = i.i_item_sk
)
SELECT 
    ts.s_store_name,
    ts.i_item_desc,
    ts.total_quantity,
    (SELECT 
        SUM(total_quantity) 
     FROM 
        Top_Sellers ts2 
     WHERE 
        ts2.sales_rank <= 5 AND ts2.s_store_name = ts.s_store_name) AS top_5_total,
    CASE 
        WHEN ts.total_quantity IS NULL THEN 'No Sales'
        ELSE 'Sales Exist'
    END AS sales_status
FROM 
    Top_Sellers ts
LEFT JOIN 
    customer c ON c.c_customer_sk = (SELECT 
                                        c_customer_sk 
                                      FROM 
                                        web_sales 
                                      WHERE 
                                        ws_item_sk = ts.ss_item_sk 
                                      LIMIT 1)
WHERE 
    ts.sales_rank <= 5
ORDER BY 
    ts.s_store_name, ts.total_quantity DESC;
