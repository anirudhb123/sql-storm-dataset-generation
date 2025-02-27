
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        c.c_gender,
        ca.ca_state,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales AS ws
    JOIN 
        customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2022
),
aggregated_sales AS (
    SELECT 
        ca.ca_state,
        d.d_year,
        d.d_month_seq,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        AVG(ws_net_profit) AS average_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_item_sk) AS unique_items_sold
    FROM 
        sales_data
    GROUP BY 
        ca.ca_state, d.d_year, d.d_month_seq
)
SELECT 
    state,
    year,
    month,
    total_sales,
    average_profit,
    total_orders,
    unique_items_sold,
    RANK() OVER (PARTITION BY year ORDER BY total_sales DESC) AS sales_rank
FROM 
    aggregated_sales
ORDER BY 
    year, sales_rank;
