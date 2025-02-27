
WITH RECURSIVE CustomerCTE AS (
    SELECT 
        c_customer_sk, 
        c_current_cdemo_sk, 
        c_first_name, 
        c_last_name, 
        c_birth_year, 
        c_birth_month, 
        c_birth_day,
        ROW_NUMBER() OVER (PARTITION BY c_current_cdemo_sk ORDER BY c_birth_year DESC) AS rn
    FROM 
        customer
    WHERE 
        c_birth_year IS NOT NULL
),
AggregatedSales AS (
    SELECT 
        c.c_current_cdemo_sk, 
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(ss.ss_ticket_number) AS sales_count
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE 
        ss.ss_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_current_cdemo_sk
),
ShippingStats AS (
    SELECT 
        ws.ws_web_site_sk,
        sm.sm_type,
        AVG(ws.ws_net_paid) AS average_net_paid
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        ws.ws_web_site_sk, sm.sm_type
)
SELECT 
    ccte.c_first_name, 
    ccte.c_last_name,
    ccte.c_current_cdemo_sk,
    asales.total_profit,
    asales.sales_count,
    sstats.average_net_paid,
    CASE 
        WHEN asales.total_profit IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status,
    CONCAT(ccte.c_first_name, ' ', ccte.c_last_name) AS full_name
FROM 
    CustomerCTE ccte
LEFT JOIN 
    AggregatedSales asales ON ccte.c_current_cdemo_sk = asales.c_current_cdemo_sk
FULL OUTER JOIN 
    ShippingStats sstats ON sstats.ws_web_site_sk = (SELECT MAX(ws_web_site_sk) FROM web_site)
WHERE 
    ccte.rn = 1 
ORDER BY 
    asales.total_profit DESC NULLS LAST, 
    ccte.c_last_name ASC;
