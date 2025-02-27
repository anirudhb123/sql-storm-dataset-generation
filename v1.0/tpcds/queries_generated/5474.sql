
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 10.00
),
SalesSummary AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS total_quantity,
        SUM(rs.ws_sales_price) AS total_sales,
        AVG(rs.ws_sales_price) AS avg_sales_price
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 5
    GROUP BY 
        rs.ws_item_sk
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_id,
        cs.total_quantity,
        cs.total_sales,
        cs.avg_sales_price
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        SalesSummary cs ON cs.ws_item_sk = ws.ws_item_sk
    WHERE 
        c.c_birth_year >= 1990
)
SELECT 
    cp.c_customer_id,
    cp.total_quantity,
    cp.total_sales,
    cp.avg_sales_price,
    d.d_month_seq,
    d.d_year
FROM 
    CustomerPurchases cp
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales WHERE ws_bill_customer_sk = cp.c_customer_id)
WHERE 
    d.d_year BETWEEN 2020 AND 2023
ORDER BY 
    cp.total_sales DESC
LIMIT 10;
