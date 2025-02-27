
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rnk
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_ext_sales_price) > 0
), 
Address_CTE AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_country
    FROM 
        customer_address
    WHERE 
        ca_state IN ('NY', 'CA') AND
        ca_city IS NOT NULL
),
Customer_Rank AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_demo_sk,
        RANK() OVER (PARTITION BY cd_demo_sk ORDER BY c_birth_year DESC) AS rank_by_birth
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE 
        cd_marital_status = 'M'
),
Sales_Summary AS (
    SELECT 
        sr_returned_date_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    GROUP BY 
        sr_returned_date_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    a.full_address,
    d.d_date AS return_date,
    s.total_returns,
    COALESCE(s.total_return_amount, 0) AS total_return_amount,
    COALESCE(rnk, 0) AS item_rank,
    COALESCE(sales.total_quantity, 0) AS total_quantity
FROM 
    Customer_Rank c
LEFT JOIN 
    Address_CTE a ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN 
    Sales_Summary s ON s.sr_returned_date_sk = c.c_first_shipto_date_sk
LEFT JOIN 
    Sales_CTE sales ON c.c_current_cdemo_sk = sales.ws_item_sk
JOIN 
    date_dim d ON d.d_date_sk = s.sr_returned_date_sk
WHERE 
    d.d_year = 2023 AND
    (c.c_email_address IS NOT NULL AND c.c_email_address <> '')
ORDER BY 
    total_return_amount DESC, 
    c.c_last_name ASC;
