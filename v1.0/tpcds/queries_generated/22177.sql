
WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws.ws_sold_date_sk
),
customer_metrics AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd.cd_credit_rating) AS highest_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
profit_analysis AS (
    SELECT 
        d.d_year,
        SUM(ss.total_profit) AS yearly_profit
    FROM 
        sales_summary ss
    JOIN 
        date_dim d ON ss.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
),
item_sales AS (
    SELECT 
        si.i_item_id,
        SUM(ws.ws_quantity) AS total_qty_sold,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_sales_price) AS total_revenue
    FROM 
        item si
    JOIN 
        web_sales ws ON si.i_item_sk = ws.ws_item_sk
    GROUP BY 
        si.i_item_id
)

SELECT 
    cm.cd_gender,
    cm.customer_count,
    cm.avg_purchase_estimate,
    COALESCE(pa.yearly_profit, 0) AS total_yearly_profit,
    is.total_qty_sold,
    is.total_revenue
FROM 
    customer_metrics cm
LEFT OUTER JOIN 
    profit_analysis pa ON 1=1
LEFT OUTER JOIN 
    item_sales is ON is.total_qty_sold > (
        SELECT 
            AVG(total_qty) 
        FROM 
            (SELECT SUM(ws.ws_quantity) AS total_qty FROM web_sales ws GROUP BY ws.ws_item_sk) AS item_totals
    )
WHERE 
    cm.customer_count IS NOT NULL
ORDER BY 
    cm.avg_purchase_estimate DESC,
    total_yearly_profit ASC
LIMIT 10;
