
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
GenderStat AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS gender_count
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
DateRange AS (
    SELECT 
        MIN(d_date) AS start_date,
        MAX(d_date) AS end_date
    FROM 
        date_dim
    WHERE 
        d_year = 2023
),
ItemPopularity AS (
    SELECT 
        i_item_id,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales 
    JOIN 
        item ON ws_item_sk = i_item_sk
    GROUP BY 
        i_item_id
),
AddressGenderJoin AS (
    SELECT 
        ai.full_address,
        ai.ca_city,
        ai.ca_state,
        gs.cd_gender,
        gs.gender_count 
    FROM 
        AddressInfo ai
    JOIN 
        customer c ON c.c_current_addr_sk = ai.ca_address_sk
    JOIN 
        GenderStat gs ON c.c_customer_sk IN (
            SELECT c_customer_sk
            FROM customer
            WHERE c_current_cdemo_sk IS NOT NULL
        )
)
SELECT
    a.ca_city,
    a.ca_state,
    AVG(a.gender_count) AS avg_gender_count,
    COUNT(DISTINCT i.i_item_id) AS unique_items_sold,
    (SELECT start_date FROM DateRange) AS start_date,
    (SELECT end_date FROM DateRange) AS end_date
FROM 
    AddressGenderJoin a
JOIN 
    ItemPopularity i ON a.full_address LIKE CONCAT('%', i.i_item_id, '%')
GROUP BY 
    a.ca_city, a.ca_state;
