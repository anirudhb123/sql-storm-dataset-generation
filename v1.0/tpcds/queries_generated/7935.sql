
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451545 AND 2451545 + 30 -- Last 30 days in TPC-DS
    GROUP BY 
        ws_item_sk
),
high_value_items AS (
    SELECT 
        i_item_id,
        i_item_desc,
        r_reason_desc,
        total_quantity,
        total_revenue
    FROM 
        ranked_sales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    JOIN 
        catalog_returns cr ON rs.ws_item_sk = cr.cr_item_sk
    JOIN 
        reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE
        rs.rank <= 10
),
customer_analysis AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(hd.hd_dep_count) AS total_dependents
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender
)
SELECT 
    hvi.i_item_id,
    hvi.i_item_desc,
    hvi.total_quantity,
    hvi.total_revenue,
    ca.c_customer_id,
    ca.cd_gender,
    ca.customer_count,
    ca.total_dependents
FROM 
    high_value_items hvi
JOIN 
    customer_analysis ca ON hvi.total_revenue > 1000 -- Filtering customers with high revenue items bought
ORDER BY 
    hvi.total_revenue DESC, 
    ca.customer_count DESC;
