
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk

    UNION ALL

    SELECT 
        ws_sold_date_sk,
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    WHERE ws_sold_date_sk < (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    GROUP BY ws_sold_date_sk, ws_item_sk
),
RankedSales AS (
    SELECT 
        ds.d_date AS sales_date,
        sd.total_quantity,
        sd.total_sales,
        RANK() OVER (PARTITION BY ds.d_date ORDER BY sd.total_sales DESC) AS sales_rank
    FROM
        SalesData sd
    JOIN date_dim ds ON sd.ws_sold_date_sk = ds.d_date_sk
    WHERE sd.total_quantity IS NOT NULL AND sd.total_sales IS NOT NULL
),
TopSales AS (
    SELECT 
        sales_date,
        total_quantity,
        total_sales,
        sales_rank
    FROM RankedSales
    WHERE sales_rank <= 10
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ts.sales_date,
        ts.total_quantity,
        ts.total_sales
    FROM 
        customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN TopSales ts ON ss.ss_sold_date_sk = (SELECT d_date_sk FROM date_dim WHERE d_date = ts.sales_date)
)
SELECT 
    c.c_first_name, 
    c.c_last_name,
    SUM(cs.total_sales) AS customer_total_sales,
    COUNT(DISTINCT cs.sales_date) AS unique_sales_dates
FROM 
    CustomerSales cs
JOIN 
    customer c ON cs.c_customer_sk = c.c_customer_sk
GROUP BY 
    c.c_first_name, 
    c.c_last_name
HAVING 
    SUM(cs.total_sales) > (SELECT AVG(total_sales) FROM TopSales)
ORDER BY 
    customer_total_sales DESC;
