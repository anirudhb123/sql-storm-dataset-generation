
WITH SalesData AS (
    SELECT 
        ws_date.d_year, 
        ws_item.i_item_id, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_paid) AS total_sales 
    FROM 
        web_sales ws
    JOIN 
        date_dim ws_date ON ws.ws_sold_date_sk = ws_date.d_date_sk
    JOIN 
        item ws_item ON ws.ws_item_sk = ws_item.i_item_sk
    WHERE 
        ws_date.d_year BETWEEN 2020 AND 2022
    GROUP BY 
        ws_date.d_year, 
        ws_item.i_item_id
),
TopItems AS (
    SELECT 
        d_year, 
        i_item_id, 
        total_quantity, 
        total_sales,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    t.d_year,
    t.i_item_id,
    t.total_quantity,
    t.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders
FROM 
    TopItems t
JOIN 
    web_sales ws ON t.i_item_id = ws.ws_item_sk
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    t.sales_rank <= 10
GROUP BY 
    t.d_year, 
    t.i_item_id, 
    t.total_quantity, 
    t.total_sales, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    ca.ca_city, 
    ca.ca_state
ORDER BY 
    t.d_year, 
    t.total_sales DESC;
