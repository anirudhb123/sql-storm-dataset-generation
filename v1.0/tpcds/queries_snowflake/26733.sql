
WITH BaseData AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        DATE(d.d_date) AS purchase_date,
        i.i_item_desc,
        ws.ws_net_profit,
        cd.cd_gender,
        COALESCE(NULLIF(cd.cd_marital_status, 'S'), 'Not Single') AS marital_status,
        HD.hd_buy_potential,
        LEFT(BrandList.BRANDSTR, 10) AS brand_short_desc
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics HD ON c.c_current_hdemo_sk = HD.hd_demo_sk
    CROSS JOIN 
        (SELECT LISTAGG(i_brand, ', ') AS BRANDSTR FROM item) AS BrandList
    WHERE 
        d.d_year = 2023 AND
        (ca.ca_state = 'CA' OR ca.ca_state = 'NY')
),
AggregatedData AS (
    SELECT 
        purchase_date,
        COUNT(DISTINCT c_customer_id) AS unique_customers,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT full_name) AS customer_count
    FROM 
        BaseData
    GROUP BY 
        purchase_date
)
SELECT 
    purchase_date,
    unique_customers,
    total_net_profit,
    customer_count,
    CASE 
        WHEN unique_customers > 100 THEN 'High Activity'
        WHEN unique_customers BETWEEN 50 AND 100 THEN 'Moderate Activity'
        ELSE 'Low Activity'
    END AS activity_level
FROM 
    AggregatedData
ORDER BY 
    purchase_date DESC;
