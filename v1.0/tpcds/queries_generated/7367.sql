
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_net_paid) AS avg_transaction_value
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_sk
),
SalesByRegion AS (
    SELECT 
        ca.ca_state,
        SUM(cs.total_sales) AS regional_sales,
        COUNT(cs.c_customer_sk) AS num_customers
    FROM 
        CustomerSales cs
    JOIN 
        customer_address ca ON ca.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = cs.c_customer_sk)
    GROUP BY 
        ca.ca_state
),
SalesGrowth AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.total_sales) AS total_store_sales,
        (SUM(ws.ws_net_paid) - SUM(cs.total_sales)) / NULLIF(SUM(cs.total_sales), 0) AS growth_rate
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN 
        store_sales cs ON cs.ss_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    sbr.ca_state,
    sbr.regional_sales,
    sbr.num_customers,
    sg.d_year,
    sg.total_web_sales,
    sg.total_store_sales,
    sg.growth_rate
FROM 
    SalesByRegion sbr
JOIN 
    SalesGrowth sg ON sg.d_year >= 2020
ORDER BY 
    sbr.regional_sales DESC, 
    sg.growth_rate DESC;
