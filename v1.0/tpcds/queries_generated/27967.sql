
WITH CustomerDetails AS (
    SELECT 
        CAST(CONCAT(c_first_name, ' ', c_last_name) AS VARCHAR(50)) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        CONCAT(ca_street_number, ' ', ca_street_name, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
DateRange AS (
    SELECT 
        d_date
    FROM 
        date_dim
    WHERE 
        d_date BETWEEN '2023-01-01' AND '2023-12-31'
),
PopularItems AS (
    SELECT 
        i_item_id, 
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM DateRange)
    GROUP BY 
        i_item_id
    ORDER BY 
        total_quantity DESC
    LIMIT 10
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    cd.full_address,
    pi.i_item_id,
    pi.total_quantity
FROM 
    CustomerDetails cd
JOIN 
    PopularItems pi ON cd.cd_purchase_estimate > 1000
ORDER BY 
    cd.cd_purchase_estimate DESC, 
    pi.total_quantity DESC
LIMIT 50;
