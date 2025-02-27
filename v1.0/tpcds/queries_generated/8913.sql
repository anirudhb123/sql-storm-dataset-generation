
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        date_dim.d_date,
        item.i_item_desc,
        customer.c_gender,
        customer.c_birth_year,
        customer.c_preferred_cust_flag,
        w.w_warehouse_name,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim ON ws.ws_sold_date_sk = date_dim.d_date_sk
    JOIN 
        item ON ws.ws_item_sk = item.i_item_sk
    JOIN 
        customer ON ws.ws_bill_customer_sk = customer.c_customer_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        date_dim.d_year = 2023
        AND item.i_current_price > 10.00
    GROUP BY 
        ws.ws_order_number, 
        ws.ws_item_sk, 
        ws.ws_sales_price, 
        ws.ws_quantity, 
        date_dim.d_date,
        item.i_item_desc,
        customer.c_gender,
        customer.c_birth_year,
        customer.c_preferred_cust_flag,
        w.w_warehouse_name
),
RankedSales AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY c_gender ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    r.c_gender,
    r.c_birth_year,
    r.w_warehouse_name,
    SUM(r.total_sales) AS gender_total_sales,
    AVG(r.ws_sales_price) AS avg_sales_price,
    COUNT(r.ws_order_number) AS total_orders
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 10
GROUP BY 
    r.c_gender, 
    r.c_birth_year, 
    r.w_warehouse_name
ORDER BY 
    gender_total_sales DESC;
