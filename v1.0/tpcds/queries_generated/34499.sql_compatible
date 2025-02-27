
WITH RECURSIVE SalesData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ws.ws_sold_date_sk DESC) AS sale_rank
    FROM 
        customer c
        JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
TotalSales AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name,
        SUM(ws_sales_price * ws_quantity) AS total_sales
    FROM 
        SalesData
    GROUP BY 
        c_customer_sk, 
        c_first_name, 
        c_last_name
),
FrequentCustomers AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name,
        LEAD(total_sales) OVER (ORDER BY total_sales DESC) AS next_total_sales
    FROM 
        TotalSales
    WHERE 
        total_sales > 1000
)
SELECT 
    fc.c_first_name,
    fc.c_last_name,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(fc.next_total_sales, 0) AS next_total_sales,
    CASE 
        WHEN ts.total_sales > COALESCE(fc.next_total_sales, 0) THEN 'Gained Sales'
        WHEN ts.total_sales < COALESCE(fc.next_total_sales, 0) THEN 'Lost Sales'
        ELSE 'No Change'
    END AS sales_trend
FROM 
    FrequentCustomers fc
LEFT JOIN 
    TotalSales ts ON ts.c_customer_sk = fc.c_customer_sk
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = fc.c_customer_sk)
WHERE 
    ca.ca_city IS NOT NULL
ORDER BY 
    total_sales DESC;
