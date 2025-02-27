
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        ws.ws_sales_price,
        ws.ws_net_paid,
        ci.c_current_addr_sk,
        ci.c_current_cdemo_sk,
        ci.c_first_name,
        ci.c_last_name,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
),
ReturnStats AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        COUNT(wr.wr_order_number) AS return_count
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
ItemStats AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(rs.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(rs.return_count, 0) AS return_count,
        (COALESCE(sd.total_sales, 0) - COALESCE(rs.total_return_quantity, 0)) AS net_sales
    FROM 
        item i
    LEFT JOIN (
        SELECT 
            ws_item_sk,
            SUM(ws_sales_price) AS total_sales
        FROM 
            web_sales
        GROUP BY 
            ws_item_sk
    ) sd ON i.i_item_sk = sd.ws_item_sk
    LEFT JOIN ReturnStats rs ON i.i_item_sk = rs.wr_item_sk
)
SELECT 
    is.i_item_sk,
    is.i_item_desc,
    is.total_sales,
    is.total_return_quantity,
    is.return_count,
    is.net_sales,
    SUM(CASE 
        WHEN sd.sales_rank = 1 THEN sd.ws_net_paid 
        ELSE 0 
    END) AS first_sale_net_paid,
    COUNT(DISTINCT sd.c_current_cdemo_sk) AS unique_customers,
    AVG(sd.ws_sales_price) AS avg_sales_price
FROM 
    ItemStats is
LEFT JOIN 
    SalesData sd ON is.i_item_sk = sd.ws_item_sk
GROUP BY 
    is.i_item_sk, is.i_item_desc, is.total_sales, is.total_return_quantity, is.return_count, is.net_sales
HAVING 
    is.net_sales > 1000
ORDER BY 
    is.net_sales DESC;
