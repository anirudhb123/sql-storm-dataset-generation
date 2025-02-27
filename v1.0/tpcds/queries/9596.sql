
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
        AND ws.ws_sales_price > 100
),
TopSales AS (
    SELECT 
        rs.ws_order_number,
        SUM(rs.ws_quantity) AS total_quantity,
        SUM(rs.ws_sales_price) AS total_sales,
        COUNT(*) AS order_count
    FROM 
        RankedSales rs
    WHERE 
        rs.rank <= 10
    GROUP BY 
        rs.ws_order_number
)
SELECT 
    ts.ws_order_number,
    ts.total_quantity,
    ts.total_sales,
    ts.order_count,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    TopSales ts
JOIN 
    customer c ON c.c_customer_sk = (SELECT ws.ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_order_number = ts.ws_order_number LIMIT 1)
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    cd.cd_gender = 'F'
ORDER BY 
    ts.total_sales DESC;
