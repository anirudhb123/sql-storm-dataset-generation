
WITH ranked_sales AS (
    SELECT 
        web_sales.ws_order_number,
        web_sales.ws_quantity,
        web_sales.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY web_sales.ws_order_number ORDER BY web_sales.ws_quantity DESC) AS rn
    FROM 
        web_sales
    WHERE 
        web_sales.ws_net_paid > 100
),
customer_info AS (
    SELECT 
        customer.c_customer_sk,
        customer.c_first_name,
        customer.c_last_name,
        customer.c_email_address,
        customer_address.ca_city,
        customer_address.ca_state,
        customer_address.ca_country,
        customer_demographics.cd_marital_status,
        CASE 
            WHEN customer_demographics.cd_gender = 'M' THEN 'Mr.'
            WHEN customer_demographics.cd_gender = 'F' THEN 'Ms.'
            ELSE 'Mx.'
        END AS salutation
    FROM 
        customer
    JOIN 
        customer_demographics ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    JOIN 
        customer_address ON customer.c_current_addr_sk = customer_address.ca_address_sk
),
inventory_summary AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM 
        inventory inv
    WHERE 
        inv.inv_quantity_on_hand IS NOT NULL
    GROUP BY 
        inv.inv_item_sk
),
sales_summary AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales_count
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sales_price > 0
    GROUP BY 
        ss.ss_item_sk
),
return_summary AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_amt) AS total_returned_amt,
        COUNT(sr_order_number) AS total_return_count
    FROM 
        store_returns 
    WHERE 
        sr_return_amt IS NOT NULL
    GROUP BY 
        sr_returning_customer_sk
)
SELECT 
    ci.salutation,
    ci.c_first_name,
    ci.c_last_name,
    ci.c_email_address,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    isNULL(sum(r.total_returned_amt), 0) AS total_returned_amount,
    sum(s.total_sales) AS total_sales_generated,
    sum(COALESCE(r.total_return_count, 0)) as total_returns,
    COUNT(DISTINCT sales.ws_order_number) AS total_orders
FROM 
    customer_info ci
LEFT JOIN 
    ranked_sales sales ON ci.c_customer_sk = sales.ws_order_number
LEFT JOIN 
    return_summary r ON r.sr_returning_customer_sk = ci.c_customer_sk
LEFT JOIN 
    sales_summary s ON s.ss_item_sk = sales.ws_item_sk
GROUP BY 
    ci.salutation,
    ci.c_first_name,
    ci.c_last_name,
    ci.c_email_address,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country
HAVING 
    SUM(s.total_sales) > 5000 
    OR MAX(s.total_sales) IS NULL
ORDER BY 
    total_sales_generated DESC, 
    ci.c_last_name, 
    ci.c_first_name;
