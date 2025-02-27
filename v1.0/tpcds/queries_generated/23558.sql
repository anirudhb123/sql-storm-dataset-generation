
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_credit_rating, 
        cd.cd_dep_count,
        (SELECT COUNT(DISTINCT wr_return_number) 
         FROM web_returns wr 
         WHERE wr.wr_returning_customer_sk = c.c_customer_sk) AS web_return_count,
        (SELECT COUNT(DISTINCT sr_ticket_number) 
         FROM store_returns sr 
         WHERE sr.sr_customer_sk = c.c_customer_sk) AS store_return_count
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender IS NOT NULL
),
AddressData AS (
    SELECT 
        ca.ca_address_sk, 
        ca.ca_city, 
        ca.ca_state, 
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca 
    LEFT JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
),
SalesData AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d) 
        AND 
        ws.ws_sold_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim d)
    GROUP BY 
        ws.ws_item_sk
    HAVING 
        total_sales > 1000
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    ad.ca_city,
    ad.ca_state,
    sd.total_sales,
    COALESCE(NULLIF(cd.web_return_count, 0), cd.store_return_count) AS return_count,
    CASE 
        WHEN sd.sales_rank = 1 THEN 'Top Sale'
        ELSE 'Regular Sale'
    END AS sale_status
FROM 
    CustomerData cd
JOIN 
    AddressData ad ON cd.c_customer_sk IN (
        SELECT c.c_customer_sk 
        FROM customer c 
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        WHERE ca.ca_city IS NOT NULL AND ca.ca_state IS NOT NULL
    )
LEFT JOIN 
    SalesData sd ON cd.c_customer_sk = sd.ws_item_sk
WHERE 
    (cd.web_return_count + cd.store_return_count) IS NOT NULL
ORDER BY 
    ad.customer_count DESC, cd.c_first_name ASC;
