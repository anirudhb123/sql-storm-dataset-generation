
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_last_name) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), AddressStats AS (
    SELECT 
        ca.ca_city, 
        ca.ca_state, 
        COUNT(*) AS total_addresses, 
        MIN(ca.ca_zip) AS min_zip, 
        MAX(ca.ca_zip) AS max_zip
    FROM customer_address ca
    GROUP BY ca.ca_city, ca.ca_state
), ItemSales AS (
    SELECT 
        i.i_item_id, 
        SUM(ws.ws_quantity) AS total_sold 
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_id
)
SELECT 
    rc.c_customer_id, 
    rc.c_first_name, 
    rc.c_last_name, 
    rc.cd_gender, 
    as.ca_city, 
    as.ca_state, 
    as.total_addresses, 
    is.total_sold
FROM RankedCustomers rc
JOIN AddressStats as ON as.ca_city = 'Los Angeles' AND as.ca_state = 'CA'
JOIN ItemSales is ON is.total_sold > 100
WHERE rc.rn <= 10
ORDER BY rc.cd_gender, rc.c_last_name, is.total_sold DESC;
