
WITH SalesData AS (
    SELECT 
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_sold_date_sk, 
        ss.ss_customer_sk
),
CustomerStats AS (
    SELECT 
        s.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_date,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_transactions, 0) AS total_transactions,
        DENSE_RANK() OVER (PARTITION BY s.c_customer_sk ORDER BY COALESCE(sd.total_sales, 0) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        SalesData sd ON c.c_customer_sk = sd.ss_customer_sk
    JOIN 
        date_dim d ON d.d_date_sk = sd.ss_sold_date_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.total_transactions,
        cs.sales_rank
    FROM 
        CustomerStats cs
    WHERE 
        cs.sales_rank <= 10
),
ShippingModes AS (
    SELECT 
        sm.sm_ship_mode_id,
        sm.sm_type,
        COUNT(ws.ws_ship_mode_sk) AS shipping_count
    FROM 
        web_sales ws
    INNER JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_ship_mode_id, sm.sm_type
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.total_transactions,
    sm.sm_type AS shipping_mode,
    COALESCE(shipping_count, 0) AS shipping_count
FROM 
    TopCustomers tc
LEFT JOIN 
    ShippingModes sm ON random() < 0.5
ORDER BY 
    total_sales DESC
LIMIT 50;
