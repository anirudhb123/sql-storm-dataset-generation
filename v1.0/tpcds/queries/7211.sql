
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        ws.ws_sold_date_sk, i.i_item_id
),
TopSellers AS (
    SELECT 
        sd.i_item_id,
        sd.total_quantity_sold,
        sd.total_sales,
        sd.total_net_profit,
        RANK() OVER (ORDER BY sd.total_net_profit DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    ts.sales_rank,
    ts.i_item_id,
    ts.total_quantity_sold,
    ts.total_sales,
    ts.total_net_profit,
    i.i_product_name,
    c.c_first_name,
    c.c_last_name
FROM 
    TopSellers ts
JOIN 
    item i ON ts.i_item_id = i.i_item_id
JOIN 
    customer c ON (SELECT COUNT(*) FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk) > 0
WHERE 
    ts.sales_rank <= 10
ORDER BY 
    ts.sales_rank;
