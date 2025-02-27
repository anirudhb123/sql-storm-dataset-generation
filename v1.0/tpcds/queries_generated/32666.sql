
WITH RECURSIVE sales_summary AS (
    SELECT 
        w.warehouse_id,
        w.warehouse_name,
        SUM(ws.quantity) AS total_quantity,
        SUM(ws.net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY w.warehouse_id ORDER BY SUM(ws.net_profit) DESC) AS rank
    FROM 
        warehouse w
    LEFT JOIN web_sales ws ON w.warehouse_sk = ws.warehouse_sk
    GROUP BY 
        w.warehouse_id, w.warehouse_name
), 
customer_rank AS (
    SELECT 
        c.c_customer_id,
        cd.education_status,
        cd.gender,
        RANK() OVER (PARTITION BY cd.education_status ORDER BY c.c_birth_year DESC) AS edu_rank
    FROM 
        customer c
    JOIN customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.gender IS NOT NULL
)
SELECT 
    ss.warehouse_name,
    ss.total_quantity,
    ss.total_profit,
    cr.c_customer_id,
    cr.education_status,
    cr.edu_rank,
    CASE 
        WHEN cr.edu_rank <= 5 THEN 'Top Educated'
        ELSE 'Others' 
    END AS customer_group,
    CASE 
        WHEN ss.total_profit IS NULL THEN 'No Profit'
        WHEN ss.total_profit > 5000 THEN 'High Profit'
        ELSE 'Moderate Profit'
    END AS profit_category
FROM 
    sales_summary ss
FULL OUTER JOIN customer_rank cr ON cr.edu_rank = 1
WHERE 
    ss.total_quantity > (SELECT AVG(total_quantity) FROM sales_summary)
ORDER BY 
    ss.total_profit DESC, cr.education_status;
