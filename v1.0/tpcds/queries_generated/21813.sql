
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk 
                               FROM date_dim d 
                               WHERE d.d_year = 2022 
                                 AND d.d_moy BETWEEN 6 AND 8)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_profit,
        RANK() OVER (ORDER BY cs.total_profit DESC) AS rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_profit IS NOT NULL
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown' 
            ELSE CASE 
                WHEN cd.cd_purchase_estimate < 1000 THEN 'Low' 
                WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium' 
                ELSE 'High' 
            END 
        END AS purchase_level
    FROM 
        customer_demographics cd 
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_profit,
    cd.cd_gender,
    cd.purchase_level
FROM 
    TopCustomers tc
LEFT JOIN CustomerDemographics cd ON tc.c_customer_sk = cd.cd_demo_sk
WHERE 
    tc.rank <= 10 AND 
    (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
ORDER BY 
    tc.total_profit DESC
UNION ALL
SELECT 
    NULL AS c_customer_sk,
    'Total' AS c_first_name,
    NULL AS c_last_name,
    SUM(total_profit) AS total_profit,
    NULL AS cd_gender,
    NULL AS purchase_level
FROM 
    TopCustomers
HAVING 
    total_profit > 1000
HAVING 
    COUNT(*) > 0;
