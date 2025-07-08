
WITH AddressCounts AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count,
        LISTAGG(DISTINCT CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') WITHIN GROUP (ORDER BY ca_street_number) AS full_address_string
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS average_purchase_estimate,
        LISTAGG(DISTINCT c.c_email_address, ', ') WITHIN GROUP (ORDER BY c.c_email_address) AS unique_emails
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_net_paid) AS total_net_sales,
        AVG(ws_net_profit) AS average_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
)
SELECT 
    ac.ca_city,
    ac.address_count,
    ac.full_address_string,
    cs.cd_gender,
    cs.customer_count,
    cs.average_purchase_estimate,
    cs.unique_emails,
    ss.ws_ship_date_sk,
    ss.total_net_sales,
    ss.average_net_profit
FROM 
    AddressCounts ac
JOIN 
    CustomerStats cs ON ac.address_count > cs.customer_count
JOIN 
    SalesSummary ss ON ss.total_net_sales > 10000
ORDER BY 
    ac.address_count DESC, cs.customer_count ASC, ss.total_net_sales DESC;
