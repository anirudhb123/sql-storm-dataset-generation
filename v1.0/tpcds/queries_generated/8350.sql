
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.web_site_id
),
TopSales AS (
    SELECT 
        web_site_id, 
        total_sales, 
        order_count 
    FROM 
        RankedSales 
    WHERE 
        rank <= 5
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(ws.ws_order_number) AS orders_made
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
    HAVING 
        COUNT(ws.ws_order_number) > 0
)
SELECT 
    ts.web_site_id,
    ts.total_sales,
    ts.order_count,
    COUNT(DISTINCT cd.c_customer_sk) AS unique_customers,
    AVG(cd.orders_made) AS avg_orders_per_customer
FROM 
    TopSales ts
LEFT JOIN 
    CustomerDetails cd ON ts.web_site_id = (
        SELECT 
            wp.web_site_id 
        FROM 
            web_page wp 
        JOIN 
            web_sales ws ON wp.wp_web_page_sk = ws.ws_web_page_sk 
        WHERE 
            ws.ws_sold_time_sk IN (SELECT DISTINCT ws_sold_time_sk FROM web_sales)
        LIMIT 1
    )
GROUP BY 
    ts.web_site_id, ts.total_sales, ts.order_count
ORDER BY 
    ts.total_sales DESC;
