
WITH customer_summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(cd.buy_potential) AS avg_buy_potential,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, d.d_year
),
active_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(cs.cs_quantity) AS total_catalog_purchases
    FROM 
        customer c
    JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    WHERE 
        cs.cs_sold_date_sk IN (SELECT ws_sold_date_sk FROM web_sales)
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
final_summary AS (
    SELECT 
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_orders,
        cs.total_spent,
        cs.avg_buy_potential,
        ac.total_catalog_purchases,
        cs.last_purchase_date
    FROM 
        customer_summary cs
    LEFT JOIN 
        active_customers ac ON cs.c_customer_id = ac.c_customer_id
)
SELECT 
    fs.c_customer_id,
    fs.c_first_name,
    fs.c_last_name,
    fs.total_orders,
    fs.total_spent,
    fs.avg_buy_potential,
    COALESCE(fs.total_catalog_purchases, 0) AS total_catalog_purchases,
    fs.last_purchase_date
FROM 
    final_summary fs
ORDER BY 
    fs.total_spent DESC
LIMIT 50;
