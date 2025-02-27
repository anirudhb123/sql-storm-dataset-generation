
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases,
        SUM(ss.ss_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
AddressStats AS (
    SELECT 
        ca.ca_country,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(cs.cs_ext_sales_price) AS revenue_generated
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        ca.ca_country
),
TimeStats AS (
    SELECT 
        d.d_year,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_sales,
        SUM(ws.ws_net_profit) AS total_web_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)

SELECT 
    cs.c_customer_id,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_purchases,
    cs.total_spent,
    a.ca_country,
    a.total_orders,
    a.revenue_generated,
    t.d_year,
    t.total_web_sales,
    t.total_web_profit
FROM 
    CustomerStats cs
JOIN 
    AddressStats a ON cs.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_current_cdemo_sk = (SELECT cd.cd_demo_sk FROM customer_demographics cd WHERE cd.cd_gender = cs.cd_gender AND cd.cd_marital_status = cs.cd_marital_status) LIMIT 1)
JOIN 
    TimeStats t ON cs.total_purchases > 0 AND a.revenue_generated > 0
ORDER BY 
    total_spent DESC, total_web_profit DESC;
