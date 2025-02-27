
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesByDemographics AS (
    SELECT 
        cd.cd_gender,
        SUM(cs.total_sales) AS gender_total_sales,
        AVG(cs.avg_profit) AS gender_avg_profit,
        SUM(cs.orders_count) AS gender_orders_count
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
SalesByTime AS (
    SELECT 
        dd.d_year,
        SUM(ws.ws_ext_sales_price) AS yearly_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        dd.d_year
),
TopItems AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id
    ORDER BY 
        total_quantity_sold DESC
    LIMIT 10
)
SELECT 
    sd.cd_gender,
    sd.gender_total_sales,
    sd.gender_avg_profit,
    sd.gender_orders_count,
    st.yearly_sales,
    ti.i_item_id,
    ti.total_quantity_sold,
    ti.total_profit
FROM 
    SalesByDemographics sd
CROSS JOIN 
    SalesByTime st
CROSS JOIN 
    TopItems ti;
