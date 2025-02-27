
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_ship_date_sk,
        d.d_year,
        d.d_quarter_seq,
        d.d_month_seq,
        d.d_week_seq,
        sm.sm_type AS ship_mode_type,
        c.cd_gender,
        ca.ca_state
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        d.d_year = 2023
),
AggSales AS (
    SELECT 
        d_year,
        d_quarter_seq,
        d_month_seq,
        ship_mode_type,
        cd_gender,
        ca_state,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM 
        SalesData
    GROUP BY 
        d_year, 
        d_quarter_seq, 
        d_month_seq, 
        ship_mode_type, 
        cd_gender, 
        ca_state
)
SELECT 
    d_year,
    d_quarter_seq,
    d_month_seq,
    ship_mode_type,
    cd_gender,
    ca_state,
    total_quantity,
    total_sales,
    RANK() OVER (PARTITION BY d_year, d_quarter_seq ORDER BY total_sales DESC) AS sales_rank
FROM 
    AggSales
WHERE 
    total_sales > 10000
ORDER BY 
    d_year, 
    d_quarter_seq, 
    sales_rank;
