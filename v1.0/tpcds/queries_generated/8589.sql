
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_paid) AS average_payment,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
),
PopularItems AS (
    SELECT 
        ws_item_sk,
        total_quantity,
        total_profit,
        total_orders,
        average_payment
    FROM 
        SalesData
    WHERE 
        profit_rank <= 10
)
SELECT 
    item.i_item_id,
    item.i_item_desc,
    address.ca_city,
    address.ca_state,
    items.total_quantity,
    items.total_profit,
    items.total_orders,
    items.average_payment
FROM 
    PopularItems items
JOIN 
    item ON items.ws_item_sk = item.i_item_sk
JOIN 
    customer AS cust ON cust.c_customer_sk = (
        SELECT 
            ws_bill_customer_sk 
        FROM 
            web_sales 
        WHERE 
            ws_item_sk = items.ws_item_sk 
        LIMIT 1
    )
JOIN 
    customer_address AS address ON cust.c_current_addr_sk = address.ca_address_sk
WHERE 
    address.ca_state IN ('CA', 'NY', 'TX')
ORDER BY 
    items.total_profit DESC;
