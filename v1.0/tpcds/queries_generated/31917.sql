
WITH RECURSIVE SalesCTE AS (
    SELECT 
        s_customer_sk,
        SUM(ss_net_profit) AS total_profit,
        COUNT(ss_ticket_number) AS ticket_count,
        ROW_NUMBER() OVER (PARTITION BY s_customer_sk ORDER BY SUM(ss_net_profit) DESC) AS rank
    FROM 
        store_sales
    GROUP BY 
        s_customer_sk
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        CASE 
            WHEN cd.cd_credit_rating IS NULL THEN 'UNRATED'
            ELSE cd.cd_credit_rating
        END AS credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
VolumeAnalysis AS (
    SELECT 
        s_store_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_store_profit
    FROM 
        store_sales
    GROUP BY 
        s_store_sk
)
SELECT 
    cd.c_customer_id, 
    cd.c_first_name, 
    cd.c_last_name, 
    cd.cd_gender,
    cd.cd_marital_status, 
    cd.ca_city, 
    cd.ca_state, 
    cd.ca_country,
    IFNULL(sa.total_profit, 0) AS customer_total_profit,
    IFNULL(sa.ticket_count, 0) AS customer_ticket_count,
    va.total_quantity,
    va.total_store_profit
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesCTE sa ON cd.c_customer_id = sa.s_customer_sk
JOIN 
    VolumeAnalysis va ON va.s_store_sk IN (
        SELECT s_store_sk FROM store_sales WHERE ss_customer_sk = cd.c_customer_id
    )
WHERE 
    cd.ca_city IS NOT NULL AND cd.ca_state = 'CA'
ORDER BY 
    customer_total_profit DESC, customer_ticket_count DESC
LIMIT 100;
