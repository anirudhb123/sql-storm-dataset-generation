
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_coupon_amt,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451935 AND 2452270 -- Filter for specific date range
),
item_sales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_web_sales_quantity,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_web_sales_amount,
        COUNT(ws.ws_order_number) AS total_web_sales_orders
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id
),
customer_with_demo AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
)
SELECT 
    cs.c_customer_id,
    cs.total_web_sales_quantity,
    cs.total_web_sales_amount,
    cs.total_web_sales_orders,
    d.d_year,
    COUNT(d.d_date_sk) FILTER (WHERE d.d_holiday = 'Y') AS holiday_count,
    AVG(p.p_discount_active::decimal) AS avg_discount_active
FROM 
    item_sales cs
JOIN 
    customer_with_demo cwd ON cs.total_web_sales_orders > 0
JOIN 
    date_dim d ON d.d_date_sk BETWEEN 2451935 AND 2452270 -- Filter for specific dates
LEFT JOIN 
    promotion p ON p.p_item_sk = cs.i_item_sk
GROUP BY 
    cs.c_customer_id, cs.total_web_sales_quantity, cs.total_web_sales_amount, cs.total_web_sales_orders, d.d_year
HAVING 
    SUM(cs.total_web_sales_amount) > 1000
ORDER BY 
    total_web_sales_amount DESC
FETCH FIRST 10 ROWS ONLY;
