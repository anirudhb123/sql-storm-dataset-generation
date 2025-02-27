
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_salutation,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_salutation
    HAVING 
        SUM(ss.ss_net_paid) IS NOT NULL

    UNION ALL

    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        ch.c_salutation,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases
    FROM 
        sales_hierarchy sh
    INNER JOIN 
        customer ch ON sh.c_customer_sk = ch.c_current_cdemo_sk
    LEFT JOIN 
        store_sales ss ON ch.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.c_salutation
    HAVING 
        COUNT(ss.ss_ticket_number) > 0
)

SELECT 
    ROW_NUMBER() OVER (PARTITION BY total_spent ORDER BY total_purchases DESC) AS rn,
    s.c_salutation || ' ' || s.c_first_name || ' ' || s.c_last_name AS full_name,
    s.total_spent, 
    s.total_purchases,
    DENSE_RANK() OVER (ORDER BY s.total_spent DESC) AS spending_rank
FROM 
    sales_hierarchy s
WHERE 
    s.total_spent > 0
ORDER BY 
    s.total_spent DESC, 
    s.total_purchases DESC
LIMIT 10;

SELECT 
    a.ca_city, 
    AVG(COALESCE(ws.ws_net_paid, 0)) AS avg_sales,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders
FROM 
    customer_address a
JOIN 
    web_sales ws ON a.ca_address_sk = ws.ws_ship_addr_sk
GROUP BY 
    a.ca_city
HAVING 
    avg_sales > 100
ORDER BY 
    avg_sales DESC;

SELECT 
    ib.ib_income_band_sk,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    SUM(COALESCE(ws.ws_net_paid, 0)) AS total_revenue
FROM 
    income_band ib
LEFT JOIN 
    household_demographics hd ON ib.ib_income_band_sk = hd.hd_income_band_sk
LEFT JOIN 
    customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    ib.ib_income_band_sk
HAVING 
    total_revenue IS NOT NULL
ORDER BY 
    total_revenue DESC
FETCH FIRST 5 ROWS ONLY;

WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_tax) AS total_tax
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk
)

SELECT 
    d.d_date,
    ss.total_sales,
    ss.order_count,
    ss.total_tax,
    ss.total_sales / NULLIF(ss.order_count, 0) AS avg_order_value
FROM 
    sales_summary ss
JOIN 
    date_dim d ON ss.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_month_seq IN (SELECT d_month_seq FROM date_dim WHERE d_year = 2023)
ORDER BY 
    d.d_date DESC;
