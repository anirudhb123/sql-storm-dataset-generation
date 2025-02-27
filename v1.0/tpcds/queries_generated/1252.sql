
WITH RankedSales AS (
    SELECT 
        ws.bill_customer_sk,
        ws_ship_addr_sk,
        ws_item_sk,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY ws.net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND ws.sold_date_sk <= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
TopCustomers AS (
    SELECT 
        r.bill_customer_sk,
        r.ws_item_sk,
        r.ws_sales_price,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY r.ws_item_sk ORDER BY r.profit_rank) AS customer_rank
    FROM 
        RankedSales r
    JOIN 
        CustomerDemographics cd ON r.bill_customer_sk = cd.cd_demo_sk
    WHERE r.profit_rank <= 10
)
SELECT 
    tc.bill_customer_sk,
    COUNT(tc.ws_item_sk) AS total_items,
    AVG(tc.ws_sales_price) AS avg_sales_price,
    STRING_AGG(DISTINCT tc.cd_gender || ': ' || tc.cd_marital_status, ', ') AS demographic_info
FROM 
    TopCustomers tc
GROUP BY 
    tc.bill_customer_sk
HAVING 
    COUNT(tc.ws_item_sk) > 1
ORDER BY 
    avg_sales_price DESC
LIMIT 10;
