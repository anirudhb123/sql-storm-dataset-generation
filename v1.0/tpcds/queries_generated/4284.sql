
WITH SalesData AS (
    SELECT 
        ws.ws_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND 
                                   (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Unknown'
        END AS gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer_demographics cd
),
HighValueCustomers AS (
    SELECT 
        sd.ws_customer_sk,
        sd.total_sales,
        cd.gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        SalesData sd
    JOIN 
        CustomerDemographics cd ON sd.ws_customer_sk = cd.cd_demo_sk
    WHERE 
        sd.total_sales > 1000
),
RankedCustomers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY gender ORDER BY total_sales DESC) AS sales_rank
    FROM 
        HighValueCustomers
)
SELECT 
    c.c_customer_id,
    COALESCE(r.total_sales, 0) AS total_sales,
    c.c_first_name,
    c.c_last_name,
    r.gender,
    r.cd_marital_status,
    r.sales_rank
FROM 
    customer c
LEFT JOIN 
    RankedCustomers r ON c.c_customer_sk = r.ws_customer_sk
WHERE 
    (c.c_birth_year < 1980 OR r.total_sales IS NULL)
ORDER BY 
    r.sales_rank, c.c_last_name DESC;
