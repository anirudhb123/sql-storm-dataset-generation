
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk
),
CustomerSpending AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        total_spent > 1000
),
HighSpenders AS (
    SELECT 
        c.customer_id,
        cs.total_spent,
        cs.total_orders
    FROM 
        CustomerSpending cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
),
TopWebsites AS (
    SELECT 
        r.web_site_id,
        rs.total_sales,
        rs.order_count
    FROM 
        RankedSales rs
    JOIN 
        web_site r ON rs.web_site_sk = r.web_site_sk
    WHERE 
        rs.rank_sales <= 5
)
SELECT 
    hw.web_site_id,
    hw.total_sales,
    hw.order_count,
    COUNT(DISTINCT hs.customer_id) AS unique_high_spenders
FROM 
    TopWebsites hw
LEFT JOIN 
    HighSpenders hs ON hs.total_spent > 1000
GROUP BY 
    hw.web_site_id, hw.total_sales, hw.order_count
ORDER BY 
    hw.total_sales DESC;
