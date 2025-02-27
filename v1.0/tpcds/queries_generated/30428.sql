
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_sold_date_sk,
        DATEADD(day, 1, d.d_date) AS next_date,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sold_date_sk) AS rn
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    UNION ALL
    SELECT 
        s.web_site_sk,
        s.ws_order_number,
        s.ws_ext_sales_price,
        s.ws_sold_date_sk,
        DATEADD(day, 1, sct.next_date) AS next_date,
        ROW_NUMBER() OVER (PARTITION BY s.ws_order_number ORDER BY s.ws_sold_date_sk) AS rn
    FROM 
        SalesCTE sct
    JOIN 
        web_sales s ON sct.web_site_sk = s.web_site_sk AND DATEADD(day, 1, sct.next_date) = DATEADD(day, 1, s.ws_sold_date_sk)
), 
AggregateSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
    GROUP BY 
        ws.web_site_sk
),
HighSellWebsites AS (
    SELECT 
        as.web_site_sk,
        as.total_sales,
        RANK() OVER (ORDER BY as.total_sales DESC) as rank
    FROM 
        AggregateSales as
    WHERE 
        as.total_sales > 1000
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    hw.web_site_id,
    hw.total_sales,
    CTE.rn,
    COALESCE(cd.cd_gender, 'Unknown') AS gender
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    HighSellWebsites hw ON hw.web_site_sk = c.c_current_cdemo_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    SalesCTE CTE ON CTE.ws_order_number = (
        SELECT ws_order_number 
        FROM web_sales ws 
        WHERE ws.ws_bill_customer_sk = c.c_customer_sk 
        ORDER BY ws.ws_sold_date_sk DESC 
        LIMIT 1
    )
WHERE 
    cd.cd_marital_status = 'M'
AND 
    CTE.rn < 10
ORDER BY 
    hw.total_sales DESC, c.c_last_name ASC;
