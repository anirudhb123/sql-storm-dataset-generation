
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        d.d_year,
        d.d_month_seq,
        s.s_store_name
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        store s ON ws.ws_ship_addr_sk = s.s_addr_sk
    WHERE 
        d.d_year = 2022
),
Summary AS (
    SELECT 
        d_year,
        d_month_seq,
        s_store_name,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        SalesData
    GROUP BY 
        d_year, d_month_seq, s_store_name
)
SELECT 
    s.d_year,
    s.d_month_seq,
    s.s_store_name,
    s.total_quantity,
    s.total_sales,
    s.total_profit,
    RANK() OVER (PARTITION BY s.d_year, s.d_month_seq ORDER BY s.total_sales DESC) AS sales_rank
FROM 
    Summary s
WHERE 
    s.total_sales > 0
ORDER BY 
    s.d_year, s.d_month_seq, sales_rank
LIMIT 100;
