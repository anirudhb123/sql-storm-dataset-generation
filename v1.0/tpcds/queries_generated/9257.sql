
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        DATE(d.d_date) AS sales_date,
        cd.gender,
        ca.state
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        d.d_month_seq BETWEEN 1 AND 12
        AND d.d_year = 2023
    GROUP BY 
        ws.ws_item_sk, DATE(d.d_date), cd.gender, ca.state
),
TopProducts AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        ROW_NUMBER() OVER (PARTITION BY sd.state ORDER BY sd.total_sales DESC) AS rank
    FROM 
        SalesData sd
)
SELECT 
    tp.ws_item_sk,
    tp.total_quantity,
    tp.total_sales,
    s.s_store_name,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders
FROM 
    TopProducts tp
JOIN 
    store_sales ss ON ss.ss_item_sk = tp.ws_item_sk
JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk
WHERE 
    tp.rank <= 5
GROUP BY 
    tp.ws_item_sk, tp.total_quantity, tp.total_sales, s.s_store_name
ORDER BY 
    s.s_store_name, tp.total_sales DESC;
