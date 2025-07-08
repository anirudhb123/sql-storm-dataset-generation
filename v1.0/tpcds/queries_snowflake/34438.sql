
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        0 AS level
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year > 1980

    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ch.level + 1
    FROM 
        CustomerHierarchy ch
    JOIN 
        customer c ON ch.c_customer_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ch.level < 3
),

ProductSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        AVG(ws.ws_sales_price) AS average_price,
        COUNT(DISTINCT ws.ws_order_number) AS sales_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year > 2021
    GROUP BY 
        ws.ws_item_sk
),

TopProducts AS (
    SELECT 
        ps.ws_item_sk,
        ps.total_sales,
        ps.average_price,
        RANK() OVER (ORDER BY ps.total_sales DESC) AS sales_rank
    FROM 
        ProductSales ps
)

SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ch.cd_gender,
    ch.cd_marital_status,
    tp.ws_item_sk,
    tp.total_sales,
    tp.average_price
FROM 
    CustomerHierarchy ch
LEFT JOIN 
    TopProducts tp ON ch.c_customer_sk = tp.ws_item_sk
WHERE 
    tp.sales_rank <= 10 OR tp.sales_rank IS NULL
ORDER BY 
    ch.c_last_name,
    ch.c_first_name;
