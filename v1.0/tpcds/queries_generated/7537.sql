
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store s ON ws.ws_store_sk = s.s_store_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M' AND 
        ws.ws_sold_date_sk BETWEEN 10000 AND 10050
    GROUP BY 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk
),
TopSales AS (
    SELECT 
        sd.ws_sold_date_sk,
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.total_discount,
        sd.total_profit
    FROM 
        SalesData sd
    WHERE 
        sd.sales_rank <= 5
)
SELECT 
    dd.d_date AS sale_date,
    i.i_item_id,
    i.i_item_desc,
    ts.total_quantity,
    ts.total_sales,
    ts.total_discount,
    ts.total_profit
FROM 
    TopSales ts
JOIN 
    date_dim dd ON ts.ws_sold_date_sk = dd.d_date_sk
JOIN 
    item i ON ts.ws_item_sk = i.i_item_sk
ORDER BY 
    dd.d_date, 
    ts.total_sales DESC;
