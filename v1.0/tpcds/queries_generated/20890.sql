
WITH RECURSIVE AddressCTE AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        ca_state,
        ca_zip,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) AS rn
    FROM 
        customer_address 
    WHERE 
        ca_state IS NOT NULL 
    UNION ALL 
    SELECT 
        a.ca_address_sk,
        a.ca_street_name,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        ROW_NUMBER() OVER (PARTITION BY a.ca_city ORDER BY a.ca_address_sk) 
    FROM 
        customer_address a 
    INNER JOIN 
        AddressCTE b ON a.ca_state = b.ca_state AND a.ca_city != b.ca_city
    WHERE 
        b.rn < 5
),
SalesCTE AS (
    SELECT 
        ws_cdemo_sk,
        SUM(ws_net_paid_inc_ship) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_cdemo_sk ORDER BY SUM(ws_net_paid_inc_ship) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= 2450000  
    GROUP BY 
        ws_cdemo_sk
),
MaxSales AS (
    SELECT 
        MAX(total_sales) AS max_sales
    FROM 
        SalesCTE
),
HighIncome AS (
    SELECT 
        hd_demo_sk,
        ib_income_band_sk 
    FROM 
        household_demographics 
    LEFT JOIN 
        income_band ON hd_income_band_sk = ib_income_band_sk 
    WHERE 
        ib_upper_bound >= 100000
)
SELECT 
    c.c_customer_id,
    a.ca_city,
    a.ca_state,
    COALESCE(SUM(s.total_sales), 0) AS total_sales,
    COALESCE(COUNT(s.order_count), 0) AS total_orders,
    CASE 
        WHEN MAX(s.total_sales) > (SELECT max_sales FROM MaxSales) THEN 'High Roller'
        ELSE 'Regular Customer'
    END AS customer_type,
    HIBIT(a.ca_zip) AS obscure_zip
FROM 
    customer c 
LEFT JOIN 
    AddressCTE a ON c.c_current_addr_sk = a.ca_address_sk 
LEFT JOIN 
    SalesCTE s ON s.ws_cdemo_sk = c.c_current_cdemo_sk 
JOIN 
    HighIncome h ON c.c_current_hdemo_sk = h.hd_demo_sk 
WHERE 
    c.c_birth_year IS NOT NULL 
    AND a.ca_street_name LIKE '%Street%'
    AND a.ca_street_name NOT LIKE '%Avenue%'
    AND (a.ca_zip IS NOT NULL OR a.ca_zip IS NULL)
GROUP BY 
    c.c_customer_id, a.ca_city, a.ca_state
ORDER BY 
    total_sales DESC, c.c_customer_id;
