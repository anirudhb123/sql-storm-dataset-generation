
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ws.ws_sales_price, 
        ws.ws_quantity, 
        ws.ws_net_profit, 
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_state,
        d.d_year,
        d.d_month_seq,
        sm.sm_type
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        d.d_year = 2023 AND 
        sm.sm_type IN ('Ground', 'Air') 
),
AggregateSales AS (
    SELECT 
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        SalesData
    GROUP BY 
        ca.ca_state, 
        cd.cd_gender, 
        cd.cd_marital_status
)
SELECT 
    ca_state,
    cd_gender,
    cd_marital_status,
    total_sales,
    total_quantity,
    avg_net_profit,
    CASE 
        WHEN total_sales > 10000 THEN 'High Sales'
        WHEN total_sales BETWEEN 5000 AND 10000 THEN 'Medium Sales'
        ELSE 'Low Sales' 
    END AS sales_category
FROM 
    AggregateSales
ORDER BY 
    total_sales DESC, 
    total_quantity DESC;
