
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        REPLACE(CONCAT(c.c_first_name, ' ', c.c_last_name), ' ', '-') AS full_name_slug,
        LENGTH(c.c_email_address) AS email_length
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
DateDetails AS (
    SELECT 
        d.d_date_id,
        d.d_month_seq,
        d.d_year,
        CASE 
            WHEN d.d_dow IN (1, 7) THEN 'Weekend'
            ELSE 'Weekday' 
        END AS day_type
    FROM 
        date_dim d
),
SalesSummary AS (
    SELECT 
        ws.ws_web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_web_site_sk
),
FinalReport AS (
    SELECT 
        cd.c_customer_id,
        cd.full_name_slug,
        cd.email_length,
        dd.d_year,
        dd.day_type,
        ss.total_sales,
        ss.total_orders,
        ss.avg_net_profit
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesSummary ss ON cd.c_customer_id = ss.ws_web_site_sk
    CROSS JOIN 
        DateDetails dd
)
SELECT 
    fr.c_customer_id,
    fr.full_name_slug,
    fr.email_length,
    fr.d_year,
    fr.day_type,
    COALESCE(fr.total_sales, 0) AS total_sales,
    COALESCE(fr.total_orders, 0) AS total_orders,
    COALESCE(fr.avg_net_profit, 0.00) AS avg_net_profit
FROM 
    FinalReport fr
WHERE 
    fr.email_length > 20
ORDER BY 
    fr.total_sales DESC;
