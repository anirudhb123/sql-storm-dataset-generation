
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(COALESCE(CASE WHEN ts IS NULL THEN 0 ELSE 1 END, 0)) AS total_transactions,
        AVG(COALESCE(ts.transaction_amount, 0)) AS average_spent,
        STRING_AGG(DISTINCT CONCAT(a.ca_street_number, ' ', a.ca_street_name, ' ', a.ca_street_type, ', ', a.ca_city, ', ', a.ca_state, ' ', a.ca_zip), '; ') AS full_address
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        (
            SELECT 
                ws_bill_customer_sk AS customer_sk,
                SUM(ws_sales_price) AS transaction_amount
            FROM 
                web_sales
            GROUP BY 
                ws_bill_customer_sk
        ) AS ts ON ts.customer_sk = c.c_customer_sk
    JOIN 
        customer_address AS a ON c.c_current_addr_sk = a.ca_address_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_transactions,
    average_spent,
    full_address
FROM 
    CustomerStats
ORDER BY 
    total_transactions DESC, average_spent DESC
LIMIT 100;
