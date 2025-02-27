
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1000 AND 2000
), average_return AS (
    SELECT 
        sr_item_sk,
        AVG(sr_return_amount) AS avg_return
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
), item_data AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_current_price,
        COALESCE(CD.cd_gender, 'U') AS gender,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        item i
    LEFT JOIN 
        customer_demographics CD ON i.i_item_sk % 10 = CD.cd_demo_sk % 10
    LEFT JOIN 
        household_demographics hd ON i.i_item_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
), sales_summary AS (
    SELECT 
        id.i_item_id,
        COUNT(DISTINCT rs.ws_order_number) AS total_orders,
        SUM(rs.ws_sales_price) AS total_sales,
        COALESCE(ar.avg_return, 0) AS average_return,
        SUM(id.i_current_price - ar.avg_return) AS sales_adjustment
    FROM 
        item_data id
    LEFT JOIN 
        ranked_sales rs ON id.i_item_sk = rs.ws_item_sk AND rs.rn = 1
    LEFT JOIN 
        average_return ar ON rs.ws_item_sk = ar.sr_item_sk
    WHERE 
        (id.gender = 'M' OR id.gender = 'F') AND 
        (id.ib_lower_bound < 50000 OR id.ib_upper_bound > 150000)
    GROUP BY 
        id.i_item_id
)
SELECT 
    ss.*, 
    (CASE 
        WHEN ss.total_sales IS NULL THEN 'No Sales' 
        WHEN ss.sales_adjustment > 0 THEN 'Profitable' 
        ELSE 'Loss'
     END) AS profitability_status
FROM 
    sales_summary ss
WHERE 
    ss.total_orders > 0
ORDER BY 
    ss.total_sales DESC 
LIMIT 50;
