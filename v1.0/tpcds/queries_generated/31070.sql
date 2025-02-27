
WITH RECURSIVE sales_dates AS (
    SELECT d_date_sk, d_date, d_year, d_month_seq
    FROM date_dim
    WHERE d_date >= '2021-01-01'
    
    UNION ALL
    
    SELECT d_date_sk + 1, d_date + interval '1 day', d_year, d_month_seq
    FROM sales_dates
    WHERE d_date < '2021-12-31'
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        sales_dates sd ON ws.ws_sold_date_sk = sd.d_date_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT
        customer_sales.*,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        customer_sales
),
sales_summary AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        top_customers tc
    LEFT JOIN 
        customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    JOIN 
        web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, hd.hd_income_band_sk
)
SELECT 
    ss.gender,
    ss.income_band_sk,
    ss.total_sales,
    ss.order_count,
    COALESCE(inv.inv_quantity_on_hand, 0) AS quantity_on_hand
FROM 
    sales_summary ss
LEFT JOIN 
    inventory inv ON ss.income_band_sk = inv.inv_item_sk
WHERE 
    ss.total_sales > (SELECT AVG(total_sales) FROM sales_summary)
ORDER BY 
    ss.total_sales DESC
LIMIT 100;
