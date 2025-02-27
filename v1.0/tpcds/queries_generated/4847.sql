
WITH sales_summary AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_bill_cdemo_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (
            SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01'
        ) AND (
            SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31'
        )
    GROUP BY 
        ws_bill_cdemo_sk
),
top_customers AS (
    SELECT 
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        ss.total_net_paid,
        ss.order_count
    FROM 
        customer cs
    JOIN 
        sales_summary ss ON cs.c_current_cdemo_sk = ss.ws_bill_cdemo_sk
    WHERE 
        ss.rank <= 10
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_net_paid, 0) AS total_net_paid,
    COALESCE(tc.order_count, 0) AS order_count,
    (SELECT 
        AVG(total_net_paid)
     FROM 
        top_customers 
     WHERE 
        total_net_paid IS NOT NULL) AS avg_purchase_value,
    (SELECT 
        COUNT(*)
     FROM 
        customer
     WHERE 
        c_preferred_cust_flag = 'Y') AS preferred_customer_count
FROM 
    top_customers tc
FULL OUTER JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT 
                                                  c.c_current_addr_sk 
                                                  FROM customer c WHERE c.c_customer_sk = tc.c_customer_id)
ORDER BY 
    tc.total_net_paid DESC;
