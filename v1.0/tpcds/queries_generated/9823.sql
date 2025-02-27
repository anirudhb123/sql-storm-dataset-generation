
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    INNER JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    WHERE 
        d_year = 2023
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        RankedSales.total_quantity,
        RankedSales.total_sales
    FROM 
        item
    JOIN 
        RankedSales ON item.i_item_sk = RankedSales.ws_item_sk
    WHERE 
        RankedSales.rank <= 10
)
SELECT 
    t.city AS store_city,
    t.state AS store_state,
    COUNT(DISTINCT web_sales.ws_order_number) AS total_orders,
    SUM(web_sales.ws_ext_sales_price) AS total_revenue,
    AVG(web_sales.ws_net_profit) AS average_profit
FROM 
    store AS t
JOIN 
    web_sales ON t.s_store_sk = web_sales.ws_ship_addr_sk
JOIN 
    TopItems ON web_sales.ws_item_sk = TopItems.i_item_sk
GROUP BY 
    t.city, t.state
ORDER BY 
    total_revenue DESC;
