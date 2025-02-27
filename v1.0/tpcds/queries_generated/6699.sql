
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price * ws_quantity) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 365 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY ws_item_sk
),
TopSellingItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        r.total_sales,
        r.order_count
    FROM RankedSales r
    JOIN item i ON r.ws_item_sk = i.i_item_sk
    WHERE r.sales_rank <= 10
),
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS customer_total_sales
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN TopSellingItems t ON ws.ws_item_sk = t.ws_item_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
)
SELECT 
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.customer_total_sales,
    tsi.i_item_desc,
    tsi.total_sales
FROM CustomerSales cs
JOIN TopSellingItems tsi ON cs.customer_total_sales > 1000
ORDER BY cs.customer_total_sales DESC, tsi.total_sales DESC;
