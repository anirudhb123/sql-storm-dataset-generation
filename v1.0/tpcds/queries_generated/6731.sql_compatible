
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY ws.web_site_id
),
TopSellingWebsites AS (
    SELECT web_site_id, total_sales, order_count 
    FROM RankedSales 
    WHERE sales_rank <= 5
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
FinalReport AS (
    SELECT 
        ts.web_site_id,
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_orders,
        cs.total_spent,
        ts.total_sales,
        ts.order_count
    FROM TopSellingWebsites ts
    CROSS JOIN CustomerStats cs
)
SELECT 
    web_site_id,
    c_customer_id,
    c_first_name,
    c_last_name,
    total_orders,
    total_spent,
    total_sales,
    order_count
FROM FinalReport
ORDER BY total_spent DESC, total_sales DESC;
