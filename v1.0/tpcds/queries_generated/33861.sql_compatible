
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        so.ss_sold_date_sk,
        SUM(so.ss_net_paid) AS total_sales,
        CASE 
            WHEN SUM(so.ss_net_paid) IS NULL THEN 'No Sales'
            WHEN SUM(so.ss_net_paid) >= 10000 THEN 'High Value'
            WHEN SUM(so.ss_net_paid) BETWEEN 5000 AND 10000 THEN 'Mid Value'
            ELSE 'Low Value'
        END AS customer_value,
        ROW_NUMBER() OVER (PARTITION BY so.ss_sold_date_sk ORDER BY SUM(so.ss_net_paid) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        store_sales so ON c.c_customer_sk = so.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, so.ss_sold_date_sk
),
DateSales AS (
    SELECT 
        dd.d_date_sk,
        dd.d_date,
        SUM(sh.total_sales) AS daily_sales,
        COUNT(CASE WHEN sh.customer_value = 'High Value' THEN 1 END) AS high_value_count
    FROM 
        date_dim dd
    LEFT JOIN 
        SalesHierarchy sh ON dd.d_date_sk = sh.ss_sold_date_sk
    GROUP BY 
        dd.d_date_sk, dd.d_date
)
SELECT 
    ds.d_date,
    ds.daily_sales,
    ds.high_value_count,
    COALESCE(ws.ws_web_site_sk, -1) AS web_site_id,
    COALESCE(ws.web_name, 'No Website') AS website_name,
    (SELECT COUNT(*) 
     FROM customer_address ca 
     WHERE ca.ca_state = 'CA' 
     AND ca.ca_country IS NOT NULL) AS valid_ca_addresses
FROM 
    DateSales ds
FULL OUTER JOIN 
    web_sales ws ON ds.d_date = (SELECT d.d_date FROM date_dim d WHERE d.d_date_sk = ws.ws_sold_date_sk)
WHERE 
    ds.daily_sales > 5000 OR ds.high_value_count > 0
ORDER BY 
    ds.d_date DESC, ds.daily_sales DESC;
