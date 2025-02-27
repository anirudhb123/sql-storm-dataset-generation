
WITH RankedSales AS (
    SELECT 
        ss_store_sk, 
        ss_sold_date_sk, 
        SUM(ss_quantity) AS total_quantity, 
        SUM(ss_net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk, ss_sold_date_sk
),
TopStores AS (
    SELECT 
        rs.ss_store_sk, 
        rs.total_quantity, 
        rs.total_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 5
),
SalesByDate AS (
    SELECT 
        dd.d_date,
        COALESCE(SUM(ts.total_sales), 0) AS daily_sales,
        COALESCE(SUM(ts.total_quantity), 0) AS daily_quantity
    FROM 
        date_dim dd
    LEFT JOIN 
        TopStores ts ON dd.d_date_sk = ts.ss_sold_date_sk
    WHERE 
        dd.d_year = 2022
    GROUP BY 
        dd.d_date
)
SELECT 
    d.d_date,
    d.daily_sales,
    d.daily_quantity,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers
FROM 
    SalesByDate d
LEFT JOIN 
    web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
LEFT JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
GROUP BY 
    d.d_date, d.daily_sales, d.daily_quantity
ORDER BY 
    d.d_date;
