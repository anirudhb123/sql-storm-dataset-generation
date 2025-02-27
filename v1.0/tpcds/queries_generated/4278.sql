
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT wr_item_sk) AS returned_items,
        SUM(wr_return_amt) AS total_return_amount,
        SUM(wr_return_tax) AS total_return_tax
    FROM 
        customer c
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returned_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
PopularItems AS (
    SELECT 
        ws.ws_item_sk,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
    HAVING 
        COUNT(ws.ws_order_number) > 3
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(pi.order_count, 0) AS order_count,
        COALESCE(pi.total_sales, 0) AS total_sales
    FROM 
        item i
    LEFT JOIN 
        PopularItems pi ON i.i_item_sk = pi.ws_item_sk
)
SELECT 
    cr.c_first_name,
    cr.c_last_name,
    id.i_item_desc,
    id.i_current_price,
    id.order_count,
    id.total_sales,
    cr.returned_items,
    cr.total_return_amount,
    cr.total_return_tax
FROM 
    CustomerReturns cr
JOIN 
    ItemDetails id ON id.i_item_sk IN (
        SELECT 
            ws_item_sk 
        FROM 
            web_sales 
        WHERE 
            ws_bill_customer_sk = cr.c_customer_sk
            AND ws_ship_date_sk IS NOT NULL
    )
WHERE 
    cr.returned_items > 0 
ORDER BY 
    cr.total_return_amount DESC, 
    cr.c_last_name, 
    cr.c_first_name;
