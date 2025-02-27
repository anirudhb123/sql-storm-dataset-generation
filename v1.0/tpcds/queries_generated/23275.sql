
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        s.ss_ticket_number,
        SUM(s.ss_quantity) AS total_quantity,
        SUM(s.ss_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(s.ss_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id, s.ss_ticket_number
),
TopCustomers AS (
    SELECT 
        r.c_customer_id,
        r.total_quantity,
        r.total_sales
    FROM 
        RankedSales r
    WHERE 
        r.sales_rank <= 3
),
SalesDetails AS (
    SELECT 
        t.c_customer_id,
        t.total_sales,
        d.d_date,
        CASE 
            WHEN t.total_sales IS NULL THEN 'No Sales'
            WHEN t.total_sales < 1000 THEN 'Low Sales'
            ELSE 'High Sales'
        END AS sales_category
    FROM 
        TopCustomers t
    LEFT JOIN 
        date_dim d ON d.d_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales ss WHERE ss.ss_ticket_number IN (SELECT ss_ticket_number FROM RankedSales WHERE c_customer_id = t.c_customer_id))
)
SELECT 
    sd.c_customer_id,
    sd.total_sales,
    sd.sales_category,
    COALESCE(sd.sales_category, 'Uncategorized') AS final_category,
    CASE 
        WHEN sd.sales_category = 'High Sales' THEN 'VIP'
        ELSE 'Regular'
    END AS customer_status,
    COUNT(DISTINCT sd.c_customer_id) OVER () AS unique_customers,
    CONCAT('Customer ID ', sd.c_customer_id, ' has ', sd.sales_category) AS customer_message,
    (SELECT 
        COUNT(*) 
     FROM 
        web_sales ws 
     WHERE 
        ws.ws_bill_customer_sk IN (SELECT c.c_customer_sk FROM customer c WHERE c.c_customer_id = sd.c_customer_id) 
        AND ws.ws_net_paid > 0) AS web_sales_count
FROM 
    SalesDetails sd
WHERE 
    sd.total_sales IS NOT NULL
ORDER BY 
    sd.total_sales DESC
LIMIT 10;
