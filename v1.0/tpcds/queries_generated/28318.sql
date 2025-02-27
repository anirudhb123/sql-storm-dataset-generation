
WITH AddressCounts AS (
    SELECT 
        ca_city, 
        ca_state, 
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
PopularItems AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc, 
        SUM(ws.ws_quantity) AS total_sales
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id, i.i_item_desc
    ORDER BY 
        total_sales DESC
    LIMIT 10
),
CustomerDemographics AS (
    SELECT 
        cd_gender, 
        cd_marital_status, 
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
),
CombinedData AS (
    SELECT 
        ac.ca_city, 
        ac.ca_state, 
        ac.address_count, 
        pi.i_item_desc, 
        pi.total_sales, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.customer_count
    FROM 
        AddressCounts ac
    LEFT JOIN 
        PopularItems pi ON ac.ca_city = (SELECT ca_city FROM customer_address WHERE ca_address_sk = c.c_current_addr_sk)
    LEFT JOIN 
        CustomerDemographics cd ON cd.cd_gender = (SELECT cd_gender FROM customer_demographics WHERE cd_demo_sk = c.c_current_cdemo_sk)
    LIMIT 100
)
SELECT 
    ca_city, 
    ca_state, 
    SUM(address_count) AS total_addresses, 
    COUNT(DISTINCT i_item_desc) AS unique_items_sold,
    SUM(total_sales) AS total_sales_amount,
    COUNT(DISTINCT cd_gender) AS unique_genders
FROM 
    CombinedData
GROUP BY 
    ca_city, ca_state
ORDER BY 
    total_sales_amount DESC
LIMIT 50;
