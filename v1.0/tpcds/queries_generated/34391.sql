
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS ranking
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CustomerCTE AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (ORDER BY cd.cd_purchase_estimate DESC) AS customer_ranking
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesByCustomer AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpenders AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS spender_rank
    FROM 
        SalesByCustomer c
    WHERE 
        total_spent > (SELECT AVG(total_spent) FROM SalesByCustomer)
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT cc.c_customer_sk) AS customer_count,
    AVG(cc.cd_purchase_estimate) AS average_purchase_estimate,
    SUM(COALESCE(ss.total_quantity, 0)) AS total_quantity_sold,
    SUM(ss.total_sales) AS total_sales_value
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    CustomerCTE cc ON c.c_customer_sk = cc.c_customer_sk
LEFT JOIN 
    SalesCTE ss ON ss.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
LEFT JOIN 
    HighSpenders hs ON c.c_customer_sk = hs.c_customer_sk
WHERE 
    ca.ca_state = 'CA' 
    AND (cc.cd_marital_status = 'M' OR cc.cd_gender = 'F') 
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT cc.c_customer_sk) > 10
ORDER BY 
    total_sales_value DESC;
