
WITH RECURSIVE sales_analysis AS (
    SELECT 
        ws.web_site_sk, 
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DATE(d.d_date) AS sales_date
    FROM 
        web_sales ws 
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_dow IN (0, 6) -- Only consider weekends
    GROUP BY 
        ws.web_site_sk, d.d_date
),
customer_info AS (
    SELECT 
        c.c_customer_sk, 
        cd.cd_gender, 
        COUNT(DISTINCT ws.ws_order_number) AS customer_orders,
        AVG(ws.ws_sales_price) AS avg_order_value,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married' 
            ELSE 'Single' 
        END AS marital_status
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS item_sales_total,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
overall_totals AS (
    SELECT 
        s.sales_date,
        SUM(s.total_sales) AS total_sales_overall,
        SUM(i.item_sales_total) AS total_item_sales,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers
    FROM 
        sales_analysis s
    LEFT JOIN 
        item_sales i ON s.web_site_sk = i.ws_item_sk
    LEFT JOIN 
        customer_info c ON c.customer_orders > 5 -- Customers with more than 5 orders
    GROUP BY 
        s.sales_date
)
SELECT 
    o.sales_date,
    o.total_sales_overall,
    o.total_item_sales,
    o.total_customers,
    COALESCE(o.total_customers, 0) * NULLIF(o.total_sales_overall, 0) AS adjusted_sales
FROM 
    overall_totals o
WHERE 
    o.total_sales_overall > (SELECT AVG(total_sales_overall) FROM overall_totals) 
ORDER BY 
    o.sales_date DESC;
