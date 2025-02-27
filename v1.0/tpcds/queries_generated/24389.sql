
WITH aggregated_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
item_details AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        a.total_quantity,
        a.total_net_profit,
        a.rank_profit
    FROM 
        item i
    LEFT JOIN 
        aggregated_sales a ON i.i_item_sk = a.ws_item_sk
),
store_info AS (
    SELECT 
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        COUNT(cc.cc_call_center_sk) AS total_call_centers
    FROM 
        store s
    LEFT JOIN 
        call_center cc ON s.s_store_sk = cc.cc_call_center_sk
    GROUP BY 
        s.s_store_id, s.s_store_name, s.s_city
),
annual_sales AS (
    SELECT 
        d.d_year,
        SUM(ws.net_paid_inc_tax) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON d.d_date_sk = ws.ws_sold_date_sk 
    GROUP BY 
        d.d_year
    HAVING 
        SUM(ws.net_paid_inc_tax) > 1000000
),
join_details AS (
    SELECT 
        id.i_item_id,
        id.i_item_desc,
        si.s_store_name,
        si.s_city,
        si.total_call_centers,
        as.total_sales
    FROM 
        item_details id
    JOIN 
        store_info si ON id.total_quantity IS NOT NULL OR id.total_quantity > 0
    LEFT JOIN 
        annual_sales as ON id.total_net_profit = as.total_sales
)
SELECT 
    jd.i_item_id,
    jd.i_item_desc,
    jd.s_store_name,
    jd.s_city,
    jd.total_call_centers,
    COALESCE(jd.total_sales, 0) AS annual_sales_value,
    CASE 
        WHEN jd.total_call_centers BETWEEN 1 AND 3 THEN 'Limited Setup'
        WHEN jd.total_call_centers > 3 THEN 'Robust Setup'
        ELSE 'No Setup'
    END AS store_setup_evaluation
FROM 
    join_details jd
WHERE 
    jd.rank_profit = 1 OR 
    (jd.total_sales IS NOT NULL AND jd.total_sales = 0)
ORDER BY 
    jd.total_net_profit DESC NULLS LAST, 
    jd.i_item_id ASC;
