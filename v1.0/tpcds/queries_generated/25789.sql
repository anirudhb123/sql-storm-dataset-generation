
WITH Customer_Info AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name, 
        ca.city, 
        ca.state, 
        cd.education_status, 
        cd.marital_status,
        ca.address_id, 
        DATE_PART('year', CURRENT_DATE) - c.c_birth_year AS age
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), Item_Info AS (
    SELECT 
        i.i_item_sk, 
        i.i_product_name, 
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        i.i_category,
        i.i_size
    FROM 
        item i
)
SELECT 
    ci.full_name,
    ci.city,
    ci.state,
    ci.age,
    ii.i_product_name,
    ii.i_item_desc,
    ii.i_current_price,
    COUNT(oi.item_sk) AS items_ordered
FROM 
    Customer_Info ci
LEFT JOIN 
    (SELECT 
        ws_bill_customer_sk AS customer_sk, 
        ws.item_sk,
        ws.order_number
    FROM 
        web_sales ws
    UNION ALL
    SELECT 
        cs_bill_customer_sk AS customer_sk, 
        cs.item_sk,
        cs.order_number
    FROM 
        catalog_sales cs) AS oi ON ci.c_customer_sk = oi.customer_sk
JOIN 
    Item_Info ii ON oi.item_sk = ii.i_item_sk
WHERE 
    ci.age >= 18 AND 
    ii.i_current_price < 50
GROUP BY 
    ci.full_name, 
    ci.city, 
    ci.state, 
    ci.age, 
    ii.i_product_name, 
    ii.i_item_desc, 
    ii.i_current_price
ORDER BY 
    items_ordered DESC, 
    ci.full_name;
