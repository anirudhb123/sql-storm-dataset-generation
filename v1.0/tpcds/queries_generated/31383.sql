
WITH RECURSIVE revenue_cte AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank 
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        CASE 
            WHEN cd.cd_gender = 'F' THEN 'Female'
            WHEN cd.cd_gender = 'M' THEN 'Male'
            ELSE 'Unknown'
        END AS gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_buy_potential, 'Low') AS buy_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
sales_summary AS (
    SELECT 
        DATE(d.d_date) AS sale_date,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(ws.ws_net_profit) AS highest_profit,
        AVG(ws.ws_sales_price) AS avg_item_price
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        DATE(d.d_date)
),
returns_summary AS (
    SELECT 
        cr_returned_date_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(cr_order_number) AS total_returns
    FROM 
        catalog_returns
    GROUP BY 
        cr_returned_date_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ci.gender,
    ci.marital_status,
    rs.sale_date,
    rs.total_sales,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    (rs.total_sales - COALESCE(r.total_return_amount, 0)) AS net_sales,
    COALESCE(ROUND(SUM(rv.total_profit), 2), 0) AS total_profit,
    rv.rank
FROM 
    customer_info ci
JOIN 
    sales_summary rs ON ci.c_customer_id = rs.sale_date
LEFT JOIN 
    returns_summary r ON r.cr_returned_date_sk = rs.sale_date
LEFT JOIN 
    revenue_cte rv ON rv.ws_item_sk = ci.c_customer_id
WHERE 
    ci.marital_status IN ('M', 'S')
    AND rv.rank <= 10
GROUP BY 
    ci.c_customer_id, ci.c_first_name, ci.c_last_name, 
    ci.gender, ci.marital_status, rs.sale_date,
    rs.total_sales, r.total_return_amount, rv.rank
ORDER BY 
    total_sales DESC, ci.c_last_name ASC;
