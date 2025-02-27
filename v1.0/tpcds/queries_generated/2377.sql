
WITH sales_data AS (
    SELECT 
        w.warehouse_id,
        SUM(ws.ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        COUNT(ws.item_sk) AS total_items_sold,
        AVG(ws.net_profit) AS avg_profit
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.warehouse_sk = w.warehouse_sk
    WHERE 
        ws.sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        w.warehouse_id
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        hd.hd_income_band_sk,
        CASE 
            WHEN hd.hd_buy_potential = 'High' THEN 'High Value'
            WHEN hd.hd_buy_potential = 'Medium' THEN 'Medium Value'
            ELSE 'Low Value' 
        END AS customer_value
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
top_sales AS (
    SELECT 
        warehouse_id,
        total_sales,
        total_orders,
        total_items_sold,
        avg_profit,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_data
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.hd_income_band_sk,
    ts.total_sales,
    ts.total_orders,
    ts.avg_profit,
    COALESCE(ts.sales_rank, 'Not Ranked') AS sales_rank,
    CASE 
        WHEN ts.total_sales IS NULL THEN 'No Sales'
        ELSE CONCAT('Sales Recorded: $', ROUND(ts.total_sales, 2))
    END AS sales_status
FROM 
    customer c
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    top_sales ts ON c.c_customer_id = (SELECT s.ws_bill_customer_sk FROM web_sales s WHERE s.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023))
WHERE 
    cd.cd_gender = 'F' 
    AND cd.hd_income_band_sk IS NOT NULL
ORDER BY 
    ts.total_sales DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
