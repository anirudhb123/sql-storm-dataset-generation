
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_return_quantity,
        SUM(cr_return_amt) AS total_return_amount,
        1 AS level
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
    HAVING 
        SUM(cr_return_quantity) > 0

    UNION ALL

    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity),
        SUM(cr_return_amt),
        level + 1
    FROM 
        catalog_returns cr
    JOIN 
        CustomerReturns cr_rec ON cr.cr_returning_customer_sk = cr_rec.cr_returning_customer_sk
    WHERE 
        level < 5
    GROUP BY 
        cr_returning_customer_sk
),
AddressInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        SUM(ws.ws_sales_price) AS sales_amount
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, cd.cd_gender
    HAVING 
        SUM(ws.ws_sales_price) IS NOT NULL
    ORDER BY 
        sales_amount DESC
    LIMIT 10
)
SELECT 
    ai.c_first_name,
    ai.c_last_name,
    ai.ca_city,
    ai.ca_state,
    ai.cd_gender,
    COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    ROW_NUMBER() OVER (PARTITION BY ai.ca_city ORDER BY ai.sales_amount DESC) AS city_rank
FROM 
    AddressInfo ai
LEFT JOIN 
    CustomerReturns cr ON ai.c_customer_sk = cr.cr_returning_customer_sk
WHERE 
    ai.ca_state IN ('CA', 'NY') 
    AND ai.cd_gender IS NOT NULL
ORDER BY 
    city_rank, ai.sales_amount DESC;
