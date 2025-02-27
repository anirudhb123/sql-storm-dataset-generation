
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws 
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND d.d_moy IN (11, 12) 
    GROUP BY 
        ws.web_site_sk, ws.ws_sold_date_sk
),
TopWebsites AS (
    SELECT 
        web_site_sk, 
        ws_sold_date_sk, 
        total_quantity, 
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
),
AddressInfo AS (
    SELECT
        w.web_site_id,
        w.web_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        tw.total_quantity,
        tw.total_sales
    FROM 
        TopWebsites tw
    JOIN 
        web_site w ON tw.web_site_sk = w.web_site_sk
    JOIN 
        customer c ON tw.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    ai.web_site_id,
    ai.web_name,
    ai.ca_city,
    ai.ca_state,
    ai.ca_country,
    SUM(ai.total_quantity) AS total_quantity_sold,
    SUM(ai.total_sales) AS total_sales_value
FROM 
    AddressInfo ai
GROUP BY 
    ai.web_site_id, ai.web_name, ai.ca_city, ai.ca_state, ai.ca_country
ORDER BY 
    total_sales_value DESC;
