
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        cd.cd_gender,
        d.d_year,
        w.w_warehouse_name,
        st.s_store_name,
        r.r_reason_desc
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN 
        web_returns wr ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN 
        reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2021
    AND 
        cd.cd_gender = 'F'
    AND 
        ws.ws_sales_price > 20.00
),
AggregatedSales AS (
    SELECT 
        d_year,
        w_warehouse_name,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        COUNT(ws_item_sk) AS total_items_sold
    FROM 
        SalesData
    GROUP BY 
        d_year, w_warehouse_name
)
SELECT 
    d_year,
    w_warehouse_name,
    total_sales,
    total_orders,
    total_items_sold,
    RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM 
    AggregatedSales
ORDER BY 
    d_year, sales_rank;
