
WITH RECURSIVE RevenueCTE AS (
    SELECT 
        s_store_sk, 
        SUM(ss_net_paid) AS total_revenue,
        COUNT(DISTINCT ss_ticket_number) AS transaction_count
    FROM 
        store_sales 
    WHERE 
        ss_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
    GROUP BY 
        s_store_sk
    UNION ALL
    SELECT 
        ss_store_sk, 
        rc.total_revenue + SUM(ss_net_paid) AS total_revenue,
        rc.transaction_count + COUNT(DISTINCT ss_ticket_number) AS transaction_count
    FROM 
        store_sales ss
    INNER JOIN 
        RevenueCTE rc ON ss.s_store_sk = rc.s_store_sk 
    WHERE 
        ss_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-02-01')
    GROUP BY 
        ss_store_sk
),
SalesData AS (
    SELECT 
        c.c_customer_id, 
        ca.ca_country, 
        SUM(ws.ws_net_paid) AS total_web_sales 
    FROM 
        web_sales ws 
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk 
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
    GROUP BY 
        c.c_customer_id, 
        ca.ca_country
),
SalesComparison AS (
    SELECT 
        sd.c_customer_id, 
        sd.ca_country,
        sd.total_web_sales,
        rc.total_revenue,
        CASE 
            WHEN rc.total_revenue IS NULL THEN 0 
            ELSE (sd.total_web_sales / rc.total_revenue) * 100 
        END AS web_sales_percentage
    FROM 
        SalesData sd
    LEFT JOIN 
        RevenueCTE rc ON sd.c_customer_id = rc.s_store_sk  -- Assuming customer_id relates to store_sk (for the sake of example)
)
SELECT 
    ca.ca_country,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    AVG(sc.web_sales_percentage) AS avg_web_sales_percentage,
    MAX(sc.total_web_sales) AS max_web_sales
FROM 
    SalesComparison sc
JOIN 
    customer_address ca ON sc.ca_country = ca.ca_country
GROUP BY 
    ca.ca_country
HAVING 
    AVG(sc.web_sales_percentage) > 50
ORDER BY 
    max_web_sales DESC;
