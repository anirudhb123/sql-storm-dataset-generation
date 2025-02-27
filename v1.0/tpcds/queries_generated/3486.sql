
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS avg_order_value,
        COUNT(ws.ws_item_sk) AS item_count,
        MAX(ws.ws_net_paid) AS max_order_value
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
HighValueCustomers AS (
    SELECT 
        c_customer_id,
        total_sales,
        order_count,
        avg_order_value,
        item_count,
        max_order_value
    FROM 
        CustomerSales
    WHERE 
        total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
),
FrequentItems AS (
    SELECT 
        ws.ws_item_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_frequency
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
    HAVING 
        order_frequency > 10
),
SalesSummary AS (
    SELECT 
        hw.c_customer_id,
        hw.total_sales,
        hw.order_count,
        hw.avg_order_value,
        fi.ws_item_sk,
        fi.order_frequency
    FROM 
        HighValueCustomers hw
    JOIN 
        FrequentItems fi ON hw.total_sales > 1000
)
SELECT 
    s.c_customer_id,
    s.total_sales,
    s.order_count,
    s.avg_order_value,
    s.max_order_value,
    fi.order_frequency
FROM 
    SalesSummary s
LEFT JOIN 
    web_page wp ON s.max_order_value = wp.wp_char_count
WHERE 
    s.avg_order_value IS NOT NULL
ORDER BY 
    s.total_sales DESC;
