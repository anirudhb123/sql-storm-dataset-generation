
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
        AND i.i_current_price > 10
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
), 
TopSales AS (
    SELECT 
        rs.ws_item_sk, 
        rs.total_quantity, 
        rs.total_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.rank <= 10
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ts.total_quantity,
    ts.total_sales,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    MAX(ts.total_sales) AS max_sales,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers
FROM 
    TopSales ts
JOIN 
    item i ON ts.ws_item_sk = i.i_item_sk
JOIN 
    web_sales ws ON ts.ws_order_number = ws.ws_order_number
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY 
    i.i_item_id, i.i_item_desc, ts.total_quantity, ts.total_sales
ORDER BY 
    ts.total_sales DESC
LIMIT 100;
