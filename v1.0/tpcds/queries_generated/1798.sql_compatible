
WITH sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        item.i_current_price,
        item.i_item_desc,
        w.w_warehouse_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        web_sales ws
    JOIN 
        item ON ws.ws_item_sk = item.i_item_sk
    LEFT JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk > 2400
        AND item.i_current_price BETWEEN 10.00 AND 100.00
),

return_data AS (
    SELECT 
        wr.wr_order_number,
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(wr.wr_return_quantity) AS return_count
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_order_number, wr.wr_item_sk
),

sales_summary AS (
    SELECT 
        sd.ws_order_number,
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS total_sold,
        SUM(sd.ws_net_paid) AS total_sales,
        AVG(sd.ws_sales_price) AS avg_sales_price,
        MAX(sd.ws_sales_price) AS max_sales_price,
        MIN(sd.ws_sales_price) AS min_sales_price,
        COALESCE(rd.total_returns, 0) AS total_returns,
        COALESCE(rd.total_return_amount, 0) AS total_return_amount,
        COUNT(DISTINCT sd.ws_order_number) AS order_count
    FROM 
        sales_data sd
    LEFT JOIN 
        return_data rd ON sd.ws_order_number = rd.wr_order_number AND sd.ws_item_sk = rd.wr_item_sk
    GROUP BY 
        sd.ws_order_number, sd.ws_item_sk
)

SELECT 
    ss.ws_order_number,
    ss.ws_item_sk,
    ss.total_sold,
    ss.total_sales,
    ss.avg_sales_price,
    ss.max_sales_price,
    ss.min_sales_price,
    ss.total_returns,
    ss.total_return_amount,
    ROW_NUMBER() OVER (PARTITION BY ss.ws_item_sk ORDER BY ss.total_sales DESC) AS rank_by_sales
FROM 
    sales_summary ss
WHERE 
    ss.total_sales > 0
ORDER BY 
    ss.total_sales DESC
LIMIT 100;
