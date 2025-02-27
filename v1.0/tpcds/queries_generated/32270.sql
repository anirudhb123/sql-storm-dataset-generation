
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        c_current_cdemo_sk, 
        1 AS level
    FROM 
        customer 
    WHERE 
        c_current_cdemo_sk IS NOT NULL
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        c.c_current_cdemo_sk, 
        ch.level + 1 
    FROM 
        customer c
    JOIN 
        CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        DENSE_RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim) - 30
),
TopSales AS (
    SELECT 
        order_number, 
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity
    FROM 
        SalesData
    WHERE 
        sales_rank <= 10
    GROUP BY 
        order_number
)
SELECT 
    ch.c_first_name, 
    ch.c_last_name, 
    ts.total_sales,
    ts.total_quantity,
    ca.ca_city,
    ca.ca_state,
    COALESCE(da.d_day_name, 'Unknown') AS last_order_day,
    COUNT(DISTINCT ts.order_number) AS order_count
FROM 
    CustomerHierarchy ch
LEFT JOIN 
    customer_demographics cd ON ch.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    store s ON ch.c_current_addr_sk = s.s_store_sk
JOIN 
    TopSales ts ON ch.c_customer_sk = ts.order_number
LEFT JOIN 
    customer_address ca ON ch.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    date_dim da ON ts.order_number = da.d_date_sk
WHERE 
    cd.cd_gender = 'F' 
    AND cd.cd_marital_status = 'M' 
    AND cd.cd_credit_rating IS NOT NULL
    AND (cd.cd_dep_count > 0 OR cd.cd_dep_employed_count > 0)
    AND (ca.ca_state IS NOT NULL OR ca.ca_country = 'USA')
ORDER BY 
    total_sales DESC, 
    order_count ASC
LIMIT 100;
