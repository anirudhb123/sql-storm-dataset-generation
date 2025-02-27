
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(cs.cs_net_profit), 0) AS total_profit,
        1 AS level
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    
    UNION ALL 
    
    SELECT 
        cu.c_customer_sk,
        cu.c_first_name,
        cu.c_last_name,
        COALESCE(SUM(cs.cs_net_profit), 0) + sh.total_profit AS total_profit,
        sh.level + 1
    FROM 
        SalesHierarchy sh
    JOIN 
        customer cu ON cu.c_current_cdemo_sk = sh.c_customer_sk
    LEFT JOIN 
        catalog_sales cs ON cu.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        cu.c_customer_sk, cu.c_first_name, cu.c_last_name, sh.total_profit, sh.level
),
FilteredSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        sh.total_profit,
        DENSE_RANK() OVER (ORDER BY sh.total_profit DESC) AS profit_rank
    FROM 
        SalesHierarchy sh
    JOIN 
        customer c ON c.c_customer_sk = sh.c_customer_sk
)
SELECT 
    f.c_customer_id,
    f.c_first_name,
    f.c_last_name,
    f.total_profit,
    f.profit_rank,
    a.ca_city,
    a.ca_state,
    d.d_date,
    sm.sm_type,
    COALESCE(ROUND(SUM(ss.ss_net_paid_inc_tax), 2), 0) AS total_sales,
    COALESCE(SUM(ss.ss_net_profit), 0) AS total_net_profit,
    CASE 
        WHEN SUM(ss.ss_net_paid_inc_tax) IS NULL THEN 'No Sales'
        WHEN ROUND(SUM(ss.ss_net_paid_inc_tax), 2) > 1000 THEN 'High Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    FilteredSales f
LEFT JOIN 
    store_sales ss ON f.c_customer_id = ss.ss_customer_sk
LEFT JOIN 
    customer_address a ON f.c_customer_sk = a.ca_address_sk
LEFT JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN 
    ship_mode sm ON ss.ss_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    f.profit_rank <= 10
GROUP BY 
    f.c_customer_id, f.c_first_name, f.c_last_name, f.total_profit, f.profit_rank, a.ca_city, a.ca_state, d.d_date, sm.sm_type
ORDER BY 
    f.total_profit DESC;
