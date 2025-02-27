
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws 
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        ws.web_site_id
),
TopSales AS (
    SELECT 
        web_site_id,
        total_sales,
        order_count
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
)
SELECT 
    ts.web_site_id,
    ts.total_sales,
    ts.order_count,
    COALESCE(SUM(ws.ws_ext_discount_amt), 0) AS total_discount,
    (SELECT COUNT(DISTINCT wr.wr_order_number) 
     FROM web_returns wr 
     WHERE wr.wr_returning_customer_sk IN 
         (SELECT DISTINCT c.c_customer_sk 
          FROM customer c 
          JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
          WHERE ts.web_site_id = ws.ws_web_site_sk)) AS total_returns,
    AVG(i.i_current_price) AS avg_item_price
FROM 
    TopSales ts
LEFT JOIN 
    web_sales ws ON ts.web_site_id = ws.ws_web_site_sk
LEFT JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
GROUP BY 
    ts.web_site_id, 
    ts.total_sales, 
    ts.order_count
ORDER BY 
    ts.total_sales DESC;
