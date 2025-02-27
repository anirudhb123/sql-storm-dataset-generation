
WITH RECURSIVE dates AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_date >= '2023-01-01'
    UNION ALL
    SELECT d.d_date_sk, d.d_date
    FROM date_dim d
    JOIN dates previous ON d.d_date_sk = previous.d_date_sk + 1
),
sales_data AS (
    SELECT 
        ws.ws_order_number, 
        ws.ws_quantity, 
        ws.ws_net_paid_inc_tax, 
        ws.ws_item_sk, 
        d.d_date,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_paid_inc_tax DESC) as rnk
    FROM web_sales ws
    JOIN dates d ON ws.ws_sold_date_sk = d.d_date_sk
),
returns_data AS (
    SELECT 
        sr_ticket_number, 
        SUM(sr_return_quantity) AS total_returns, 
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    GROUP BY sr_ticket_number
)
SELECT 
    s.ws_order_number, 
    SUM(sd.ws_quantity) AS total_sold_quantity,
    SUM(sd.ws_net_paid_inc_tax) AS total_sales,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN SUM(sd.ws_net_paid_inc_tax) > 1000 THEN 'High Value'
        ELSE 'Low Value'
    END AS sales_category
FROM sales_data sd
LEFT JOIN returns_data r ON sd.ws_order_number = r.sr_ticket_number
GROUP BY s.ws_order_number
HAVING total_sold_quantity > 5
ORDER BY total_sales DESC
LIMIT 100;
