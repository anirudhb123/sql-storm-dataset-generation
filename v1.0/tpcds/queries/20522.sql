
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        COALESCE(wr.wr_return_quantity, 0) AS total_returns,
        (ws.ws_quantity * ws.ws_sales_price) - COALESCE(wr.wr_return_amt, 0) AS net_sales
    FROM 
        web_sales ws
    LEFT JOIN 
        web_returns wr ON ws.ws_order_number = wr.wr_order_number AND ws.ws_item_sk = wr.wr_item_sk
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(ws2.ws_sold_date_sk) FROM web_sales ws2)
),
ranked_sales AS (
    SELECT 
        ss.ws_order_number,
        ss.ws_item_sk,
        ss.ws_quantity,
        ss.ws_sales_price,
        ss.total_returns,
        ss.net_sales,
        RANK() OVER (PARTITION BY ss.ws_item_sk ORDER BY ss.net_sales DESC) AS sales_rank
    FROM 
        sales_summary ss
),
address_data AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, ca.ca_address_sk, ca.ca_city, ca.ca_state
),
final_summary AS (
    SELECT 
        r.ws_order_number,
        r.ws_item_sk,
        r.ws_quantity,
        r.ws_sales_price,
        r.total_returns,
        r.net_sales,
        a.ca_city,
        a.ca_state,
        a.order_count
    FROM 
        ranked_sales r
    JOIN 
        address_data a ON r.ws_order_number IN (
            SELECT 
                ws_order_number 
            FROM 
                web_sales 
            WHERE 
                ws_bill_customer_sk = a.c_customer_sk
        )
    WHERE 
        r.sales_rank <= 5
)
SELECT
    fs.ws_order_number,
    fs.ws_item_sk,
    fs.ws_quantity,
    fs.ws_sales_price,
    fs.total_returns,
    fs.net_sales,
    fs.ca_city,
    fs.ca_state,
    fs.order_count,
    CASE 
        WHEN fs.net_sales IS NULL OR fs.net_sales = 0 THEN 'No Sales'
        WHEN fs.total_returns > 0 THEN 'Returns Exist'
        ELSE 'Successful Sale'
    END AS sale_status,
    (SELECT COUNT(*) FROM item WHERE i_item_sk = fs.ws_item_sk AND i_current_price > (SELECT AVG(i_current_price) FROM item)) AS premium_item_flag
FROM 
    final_summary fs
WHERE 
    fs.ca_state IN (SELECT DISTINCT ca_state FROM customer_address WHERE ca_city IS NOT NULL)
ORDER BY 
    fs.net_sales DESC, fs.ca_city ASC;
