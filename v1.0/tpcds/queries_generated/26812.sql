
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 2000
),
FrequentShoppers AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        RankedCustomers rc ON ws.ws_bill_customer_sk = rc.c_customer_sk
    GROUP BY 
        ws.bill_customer_sk
    HAVING 
        SUM(ws.ws_quantity) > 10
),
TopFrequentShoppers AS (
    SELECT 
        rc.full_name,
        fs.total_quantity,
        fs.total_spent,
        ROW_NUMBER() OVER (ORDER BY fs.total_spent DESC) AS rank
    FROM 
        FrequentShoppers fs
    JOIN 
        RankedCustomers rc ON fs.bill_customer_sk = rc.c_customer_sk
)
SELECT 
    full_name,
    total_quantity,
    total_spent,
    rank
FROM 
    TopFrequentShoppers
WHERE 
    rank <= 10
ORDER BY 
    total_spent DESC;
