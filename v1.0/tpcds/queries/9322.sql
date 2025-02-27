
WITH sales_summary AS (
    SELECT 
        customer.c_customer_id, 
        customer.c_first_name, 
        customer.c_last_name, 
        COUNT(DISTINCT web_sales.ws_order_number) AS total_orders,
        SUM(web_sales.ws_net_paid_inc_tax) AS total_spent,
        AVG(web_sales.ws_net_paid_inc_tax) AS avg_order_value,
        COUNT(DISTINCT store_returns.sr_ticket_number) AS total_returns,
        SUM(store_returns.sr_return_amt_inc_tax) AS total_returned
    FROM 
        customer
    LEFT JOIN 
        web_sales ON customer.c_customer_sk = web_sales.ws_bill_customer_sk
    LEFT JOIN 
        store_returns ON customer.c_customer_sk = store_returns.sr_customer_sk
    GROUP BY 
        customer.c_customer_id, 
        customer.c_first_name, 
        customer.c_last_name
), 
demographics AS (
    SELECT 
        cd_gender, 
        cd_marital_status, 
        COUNT(*) AS customer_count, 
        SUM(total_orders) AS total_orders, 
        SUM(total_spent) AS total_spent
    FROM 
        sales_summary
    JOIN 
        customer_demographics ON customer_demographics.cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer WHERE customer.c_customer_id = sales_summary.c_customer_id)
    GROUP BY 
        cd_gender, 
        cd_marital_status
)
SELECT 
    cd_gender, 
    cd_marital_status,
    customer_count,
    total_orders,
    total_spent,
    total_spent / NULLIF(customer_count, 0) AS avg_spent_per_customer
FROM 
    demographics 
ORDER BY 
    total_spent DESC;
