
WITH RECURSIVE CustomerSalesCTE AS (
    SELECT 
        c.c_customer_sk, 
        c.c_customer_id, 
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_store_sales,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_sales,
        0 AS level
    FROM 
        customer AS c
    LEFT JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_customer_id
    
    UNION ALL
    
    SELECT 
        cs.c_customer_sk, 
        cs.c_customer_id, 
        cs.total_store_sales, 
        cs.total_web_sales, 
        level + 1
    FROM 
        CustomerSalesCTE AS cs
    JOIN 
        customer AS sub_c ON cs.c_customer_sk = sub_c.c_current_cdemo_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cpp.total_store_sales + cpp.total_web_sales AS total_sales,
    CASE 
        WHEN cpp.total_store_sales + cpp.total_web_sales > 1000 THEN 'High Value'
        WHEN (cpp.total_store_sales + cpp.total_web_sales) BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    ROW_NUMBER() OVER (PARTITION BY customer_value ORDER BY total_sales DESC) AS sales_rank
FROM 
    CustomerSalesCTE AS cpp
JOIN 
    customer AS c ON cpp.c_customer_sk = c.c_customer_sk
WHERE 
    c.c_birth_year IS NOT NULL
    AND c.c_email_address IS NOT NULL
    AND (c.c_preferred_cust_flag = 'Y' OR c.c_birth_month = 12)
ORDER BY 
    customer_value DESC, total_sales DESC;
