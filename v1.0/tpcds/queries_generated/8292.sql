
WITH sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        i.i_item_desc,
        c.c_first_name,
        c.c_last_name,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        d.d_month_seq,
        d.d_year,
        s.s_store_name
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        store s ON ws.ws_ship_addr_sk = s.s_addr_sk
    WHERE 
        d.d_year = 2023
),
total_sales AS (
    SELECT 
        d_month_seq,
        d_year,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid
    FROM 
        sales_data
    GROUP BY 
        d_month_seq, d_year
),
average_sales AS (
    SELECT 
        d_month_seq,
        d_year,
        AVG(total_net_paid) AS avg_net_paid,
        AVG(total_quantity) AS avg_quantity
    FROM 
        total_sales
    GROUP BY 
        d_month_seq, d_year
)
SELECT 
    asls.d_month_seq,
    asls.d_year,
    asls.avg_net_paid,
    asls.avg_quantity,
    COUNT(sd.ws_order_number) AS total_orders,
    SUM(sd.ws_net_paid) AS grand_total_net_paid
FROM 
    average_sales asls
JOIN 
    sales_data sd ON asls.d_month_seq = sd.d_month_seq AND asls.d_year = sd.d_year
GROUP BY 
    asls.d_month_seq, asls.d_year, asls.avg_net_paid, asls.avg_quantity
ORDER BY 
    asls.d_year, asls.d_month_seq;
