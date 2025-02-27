
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_revenue
    FROM
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        SUM(cs_quantity),
        SUM(cs_net_paid_inc_tax)
    FROM 
        catalog_sales
    GROUP BY 
        cs_sold_date_sk, cs_item_sk
),
ranked_sales AS (
    SELECT 
        sd.ws_sold_date_sk,
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_revenue,
        RANK() OVER (PARTITION BY sd.ws_sold_date_sk ORDER BY sd.total_revenue DESC) AS revenue_rank
    FROM (
        SELECT ws_sold_date_sk, ws_item_sk, total_quantity, total_revenue
        FROM sales_data
        WHERE ws_sold_date_sk BETWEEN 1 AND 365 
    ) AS sd
)
SELECT 
    dd.d_date AS sale_date,
    isnull(sm.sm_type, 'Unknown') AS shipping_method,
    r.revenue_rank,
    SUM(sd.total_revenue) AS total_revenue
FROM 
    ranked_sales r
LEFT JOIN 
    date_dim dd ON r.ws_sold_date_sk = dd.d_date_sk
LEFT JOIN 
    ship_mode sm ON r.ws_item_sk = sm.sm_ship_mode_sk  -- Assuming mapping based on ship mode skill
GROUP BY 
    sale_date, shipping_method, r.revenue_rank
HAVING 
    SUM(sd.total_revenue) > 1000
ORDER BY 
    sale_date DESC, total_revenue DESC;
