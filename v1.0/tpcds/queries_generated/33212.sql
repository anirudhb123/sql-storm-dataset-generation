
WITH RECURSIVE customer_sales AS (
    SELECT 
        ws_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_customer_sk
),
sales_by_region AS (
    SELECT 
        ca_state, 
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS distinct_orders
    FROM 
        catalog_sales 
    JOIN 
        customer ON cs_bill_customer_sk = c_customer_sk
    JOIN 
        customer_address ON c_current_addr_sk = ca_address_sk
    GROUP BY 
        ca_state
),
filtered_sales AS (
    SELECT 
        sr_store_sk,
        SUM(sr_net_loss) AS total_net_loss
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 
        (SELECT AVG(sr_return_quantity) FROM store_returns)
    GROUP BY 
        sr_store_sk
),
recent_transactions AS (
    SELECT 
        ws_order_number,
        ws_sold_date_sk,
        ws_net_paid_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_sold_date_sk DESC) AS order_rank
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk IS NOT NULL
)
SELECT 
    ca_state,
    ts.total_sales,
    RTS.ws_order_number,
    RTS.ws_net_paid_inc_tax,
    CASE 
        WHEN RTS.ws_net_paid_inc_tax IS NULL THEN 'No Payment'
        ELSE 'Payment Received'
    END AS payment_status,
    COALESCE(cs.total_profit, 0) AS total_profit,
    COALESCE(fs.total_net_loss, 0) AS total_net_loss
FROM 
    sales_by_region ts
LEFT JOIN 
    customer_sales cs ON cs.ws_customer_sk = RTS.ws_customer_sk
LEFT JOIN 
    filtered_sales fs ON fs.sr_store_sk = ts.sr_store_sk
LEFT JOIN 
    recent_transactions RTS ON RTS.order_rank = 1
WHERE 
    ts.total_sales > (SELECT AVG(total_sales) FROM sales_by_region)
ORDER BY 
    ts.total_sales DESC, total_profit DESC;
