
WITH RankedSales AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank,
        COUNT(ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY
        c.c_customer_id, c.c_first_name, c.c_last_name, ws.ws_order_number, ws.ws_sold_date_sk
),
TopCustomers AS (
    SELECT
        r.c_customer_id,
        r.c_first_name,
        r.c_last_name,
        r.total_sales,
        r.order_count
    FROM
        RankedSales r
    WHERE
        r.sales_rank <= 10
),
TotalSales AS (
    SELECT
        SUM(ss.ss_sales_price) AS total_store_sales,
        SUM(ws.ws_sales_price) AS total_web_sales
    FROM
        store_sales ss
    FULL OUTER JOIN
        web_sales ws ON ss.ss_sold_date_sk = ws.ws_sold_date_sk
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    ts.total_store_sales,
    ts.total_web_sales,
    CASE 
        WHEN tc.total_sales IS NULL THEN 'No Sales'
        WHEN ts.total_web_sales = 0 THEN 'No Online Presence'
        ELSE tc.total_sales / NULLIF(ts.total_web_sales, 0) 
    END AS sales_to_web_ratio,
    CASE 
        WHEN tc.order_count > 5 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer' 
    END AS buying_type
FROM 
    TopCustomers tc
CROSS JOIN 
    TotalSales ts
WHERE 
    tc.total_sales > (SELECT AVG(total_sales) FROM RankedSales)
ORDER BY 
    tc.total_sales DESC;
