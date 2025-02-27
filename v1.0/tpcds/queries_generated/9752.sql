
WITH customer_summary AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        SUM(sr.return_amt) AS total_return_amount,
        SUM(sr.return_tax) AS total_return_tax,
        SUM(sr.return_amt_inc_tax) AS total_return_amount_inc_tax,
        ca.state AS customer_state,
        cd.gender AS customer_gender,
        ROUND(AVG(CASE WHEN sr.return_quantity > 0 THEN sr.return_quantity END), 2) AS avg_return_quantity
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_id, ca.state, cd.gender
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_sales,
        SUM(ws_sales_price) AS total_sales_amount,
        SUM(ws_ext_discount_amt) AS total_discount_amount,
        SUM(ws_net_paid) AS total_net_paid,
        AVG(ws_quantity) AS avg_quantity_sold
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cs.c_customer_id,
    cs.total_returns,
    cs.total_return_amount,
    cs.total_return_tax,
    cs.total_return_amount_inc_tax,
    cs.customer_state,
    cs.customer_gender,
    cs.avg_return_quantity,
    ss.total_sales,
    ss.total_sales_amount,
    ss.total_discount_amount,
    ss.total_net_paid,
    ss.avg_quantity_sold
FROM 
    customer_summary cs
LEFT JOIN 
    sales_summary ss ON cs.c_customer_id = ss.ws_bill_customer_sk
ORDER BY 
    cs.total_return_amount DESC, ss.total_sales_amount DESC
LIMIT 100;
