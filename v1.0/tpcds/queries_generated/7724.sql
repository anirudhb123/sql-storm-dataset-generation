
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        d.d_year
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
),
AggregatedSales AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        d.d_year,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        SalesData
    GROUP BY 
        ca.ca_city, ca.ca_state, cd.cd_gender, d.d_year
),
RankedSales AS (
    SELECT 
        city,
        state,
        gender,
        year,
        total_quantity,
        total_sales,
        total_profit,
        RANK() OVER (PARTITION BY state, year ORDER BY total_profit DESC) AS rank_within_state
    FROM 
        AggregatedSales
)
SELECT 
    city,
    state,
    gender,
    year,
    total_quantity,
    total_sales,
    total_profit
FROM 
    RankedSales
WHERE 
    rank_within_state <= 5
ORDER BY 
    state, year, total_profit DESC;
