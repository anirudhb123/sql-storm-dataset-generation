
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_ship_mode_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number, ws.ws_ship_mode_sk
),
current_month_sales AS (
    SELECT 
        DATE_TRUNC('month', d.d_date) AS sales_month,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        sales_month
),
customer_info AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_city, ca.ca_state, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.customer_count,
    COALESCE(s.total_sales, 0) AS total_sales_last_month,
    r.sales_rank,
    CASE 
        WHEN ci.customer_count = 0 THEN 'No customers'
        ELSE 'Customers present'
    END AS customer_status
FROM 
    customer_info ci
LEFT JOIN 
    (SELECT 
        cs.ship_mode_sk,
        cs.total_sales,
        RANK() OVER (PARTITION BY cs.ship_mode_sk ORDER BY cs.total_sales DESC) AS sales_rank
     FROM 
        ranked_sales cs) r ON ci.ca_city = r.ship_mode_sk
LEFT JOIN 
    current_month_sales s ON DATE_TRUNC('month', s.sales_month) = DATE_TRUNC('month', CURRENT_DATE)
WHERE 
    (ci.ca_state IS NOT NULL OR ci.cd_gender IS NOT NULL)
    AND NOT EXISTS (
        SELECT 1 
        FROM store_sales ss
        WHERE ss.ss_sales_price < 0 AND ss.ss_item_sk IN (SELECT sr_item_sk FROM store_returns)
    )
ORDER BY 
    ci.ca_city, ci.customer_count DESC;
