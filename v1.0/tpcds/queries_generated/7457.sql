
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_sales_price,
        ws.ws_quantity,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY ws.ws_sales_price DESC) AS rank_sales
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451565  -- Considering a specific range of date_sk
        AND cd.cd_gender = 'F'  -- Focusing on female customers
        AND ca.ca_state = 'CA'  -- Limiting to California customers
),
TopSellingItems AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id
    ORDER BY 
        total_quantity DESC
    LIMIT 10
)
SELECT 
    tsi.i_item_id,
    tsi.total_quantity,
    rs.ca_city,
    COUNT(DISTINCT rs.cd_gender) AS gender_count,
    SUM(rs.ws_sales_price) AS total_sales_value
FROM 
    TopSellingItems tsi
JOIN 
    RankedSales rs ON tsi.browser_id = rs.web_site_id  -- Ensure this join condition is accurate
GROUP BY 
    tsi.i_item_id, 
    rs.ca_city
HAVING 
    COUNT(DISTINCT rs.cd_gender) > 1  -- Only including items sold to more than one gender
ORDER BY 
    total_sales_value DESC;
