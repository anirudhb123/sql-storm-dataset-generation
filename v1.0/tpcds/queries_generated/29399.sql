
WITH customer_info AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        ca.ca_city, 
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
item_info AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc, 
        i.i_current_price, 
        i.i_brand
    FROM 
        item i
), 
sales_info AS (
    SELECT 
        ws.ws_order_number, 
        ws.ws_item_sk, 
        ws.ws_sales_price, 
        ws.ws_quantity, 
        ws.ws_sold_date_sk, 
        ws.ws_bill_customer_sk
    FROM 
        web_sales ws
    UNION ALL
    SELECT 
        cs.cs_order_number, 
        cs.cs_item_sk, 
        cs.cs_sales_price, 
        cs.cs_quantity, 
        cs.cs_sold_date_sk, 
        cs.cs_bill_customer_sk
    FROM 
        catalog_sales cs
    UNION ALL
    SELECT 
        ss.ss_ticket_number, 
        ss.ss_item_sk, 
        ss.ss_sales_price, 
        ss.ss_quantity, 
        ss.ss_sold_date_sk, 
        ss.ss_customer_sk
    FROM 
        store_sales ss
)
SELECT 
    ci.full_name, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ii.i_item_desc, 
    ii.i_current_price, 
    SUM(si.ws_quantity) AS total_quantity_sold, 
    SUM(si.ws_sales_price * si.ws_quantity) AS total_sales_amount
FROM 
    customer_info ci
JOIN 
    sales_info si ON ci.c_customer_id = si.ws_bill_customer_sk
JOIN 
    item_info ii ON si.ws_item_sk = ii.i_item_sk
GROUP BY 
    ci.full_name, ci.cd_gender, ci.cd_marital_status, ii.i_item_desc, ii.i_current_price
HAVING 
    total_sales_amount > 1000
ORDER BY 
    total_sales_amount DESC;
