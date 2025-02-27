
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ItemSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
TopSellingItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        is.total_quantity_sold,
        is.total_sales
    FROM 
        item i
    JOIN 
        ItemSales is ON i.i_item_sk = is.ws_item_sk
    ORDER BY 
        is.total_sales DESC
    LIMIT 10
),
ReturnStats AS (
    SELECT 
        sr_item_sk, 
        COUNT(sr_return_quantity) AS total_returns, 
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns 
    GROUP BY 
        sr_item_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    tsi.i_item_id,
    tsi.i_item_desc,
    tsi.total_quantity_sold,
    tsi.total_sales,
    rs.total_returns,
    rs.total_return_amount
FROM 
    CustomerInfo ci
JOIN 
    TopSellingItems tsi ON ci.c_customer_id = (SELECT c_customer_id FROM customer WHERE c_customer_sk = ci.c_customer_sk LIMIT 1)
LEFT JOIN 
    ReturnStats rs ON tsi.i_item_id = (SELECT i_item_id FROM item WHERE i_item_sk = rs.sr_item_sk LIMIT 1)
WHERE 
    ci.cd_gender = 'F' 
    AND ci.cd_marital_status = 'M' 
    AND ci.cd_purchase_estimate > 1000
ORDER BY 
    tsi.total_sales DESC
LIMIT 50;
