
WITH ranked_sales AS (
    SELECT 
        cs.s_old_date_sk,
        cs.sales_price,
        cs.quantity,
        c.c_gender,
        cd.edu_status,
        d.d_year,
        SUM(cs.net_profit) OVER (PARTITION BY cs.s_old_date_sk ORDER BY cs.s_order_number DESC) AS cumulative_profit
    FROM 
        catalog_sales cs
    JOIN 
        customer c ON cs.bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON cs.s_old_date_sk = d.d_date_sk
    WHERE 
        c.c_current_addr_sk IN (SELECT DISTINCT ca_address_sk FROM customer_address WHERE ca_state = 'CA')
        AND d.d_year BETWEEN 2015 AND 2020
),
average_profit AS (
    SELECT 
        d_year,
        AVG(cumulative_profit) AS avg_cumulative_profit
    FROM 
        ranked_sales
    GROUP BY 
        d_year
)
SELECT 
    a.d_year,
    a.avg_cumulative_profit,
    s.w_warehouse_name,
    sm.sm_type
FROM 
    average_profit a
JOIN 
    warehouse s ON s.w_warehouse_sk = (SELECT w_warehouse_sk FROM inventory WHERE inv_date_sk = a.d_year)
JOIN 
    ship_mode sm ON sm.sm_ship_mode_sk = (SELECT sm_ship_mode_sk FROM catalog_sales WHERE cs_sold_date_sk = a.d_year LIMIT 1)
ORDER BY 
    a.d_year;
