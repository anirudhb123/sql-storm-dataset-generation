
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rnk
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year >= 1970 
        AND c.c_birth_year <= 1990 
        AND (c.c_gender = 'F' OR c.c_gender IS NULL)
        AND i.i_current_price > 10.00
    GROUP BY 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk
),
TopSales AS (
    SELECT 
        rs.ws_sold_date_sk,
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.rnk <= 10
)
SELECT 
    dd.d_date,
    ts.ws_item_sk,
    ts.total_quantity,
    ts.total_sales,
    ts.total_sales / NULLIF(ts.total_quantity, 0) AS avg_sales_price
FROM 
    TopSales ts
JOIN 
    date_dim dd ON ts.ws_sold_date_sk = dd.d_date_sk
ORDER BY 
    dd.d_date, 
    ts.total_sales DESC;
