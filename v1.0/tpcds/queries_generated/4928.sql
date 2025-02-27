
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
return_data AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(wr.wr_order_number) AS return_count
    FROM 
        web_returns wr
    JOIN 
        date_dim dd ON wr.wr_returned_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        wr.wr_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_credit_rating ORDER BY c.c_first_name) AS ranking
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 5000
),
total_sales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_sales,
        COALESCE(rd.total_return_amt, 0) AS total_return_amt,
        (sd.total_sales - COALESCE(rd.total_return_amt, 0)) AS net_sales
    FROM 
        sales_data sd
    LEFT JOIN 
        return_data rd ON sd.ws_item_sk = rd.wr_item_sk
)
SELECT 
    tsi.warehouse_id,
    tsi.warehouse_name,
    COALESCE(t_sales.total_sales, 0) AS total_sales,
    COALESCE(t_sales.total_return_amt, 0) AS total_return_amt,
    t_sales.net_sales,
    STRING_AGG(CONCAT(ci.c_first_name, ' ', ci.c_last_name), ', ') AS top_customers
FROM 
    total_sales t_sales
JOIN 
    inventory inv ON t_sales.ws_item_sk = inv.inv_item_sk
JOIN 
    warehouse tsi ON inv.inv_warehouse_sk = tsi.w_warehouse_sk
LEFT JOIN 
    customer_info ci ON ci.c_customer_sk IN (
        SELECT 
            c_customer_sk 
        FROM 
            sales_data sd 
        WHERE 
            sd.ws_item_sk = t_sales.ws_item_sk 
        ORDER BY 
            sd.total_sales DESC 
        LIMIT 5
    )
GROUP BY 
    tsi.warehouse_id, 
    tsi.warehouse_name
HAVING 
    net_sales > 10000
ORDER BY 
    total_sales DESC;
