
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL AND
        i.i_current_price > 50.00
),
monthly_sales AS (
    SELECT 
        dd.d_year,
        dd.d_month_seq,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
    GROUP BY 
        dd.d_year, dd.d_month_seq
)

SELECT 
    ca.ca_country,
    COALESCE(MAX(rs.ws_sales_price), 0) AS max_sales_price,
    COALESCE(SUM(ms.total_sales), 0) AS total_monthly_sales,
    COUNT(DISTINCT cs.cs_order_number) AS total_catalog_sales,
    AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
    COUNT(DISTINCT wr.wr_order_number) AS total_web_returns
FROM 
    customer_address ca
LEFT JOIN 
    (SELECT ca_address_sk, ca_country FROM customer c JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk) AS cust_addr ON ca.ca_address_sk = cust_addr.ca_address_sk
LEFT JOIN 
    ranked_sales rs ON ca.ca_address_sk = rs.ws_item_sk
LEFT JOIN 
    monthly_sales ms ON 1 = 1
LEFT JOIN 
    catalog_sales cs ON ca.ca_address_sk = cs.cs_ship_addr_sk
LEFT JOIN 
    web_returns wr ON wr.wr_returning_addr_sk = ca.ca_address_sk
LEFT JOIN 
    household_demographics hd ON hd.hd_demo_sk = (SELECT cd_demo_sk FROM customer_demographics WHERE cd_demo_sk = c.c_current_cdemo_sk)
WHERE 
    ca.ca_country IS NOT NULL
GROUP BY 
    ca.ca_country
HAVING 
    COUNT(DISTINCT rs.ws_item_sk) > 5
ORDER BY 
    total_monthly_sales DESC;
