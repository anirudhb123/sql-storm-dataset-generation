
WITH AddressDetails AS (
    SELECT 
        ca_city, 
        ca_state, 
        COUNT(*) AS AddressCount, 
        STRING_AGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') AS FullAddress
    FROM customer_address
    GROUP BY 
        ca_city, 
        ca_state
), 
DemographicDetails AS (
    SELECT 
        CASE 
            WHEN cd_gender = 'M' THEN 'Male' 
            ELSE 'Female' 
        END AS Gender, 
        cd_marital_status AS MaritalStatus, 
        COUNT(DISTINCT c.c_customer_sk) AS CustomerCount
    FROM customer_demographics cd
    JOIN customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender, 
        cd_marital_status
), 
SalesData AS (
    SELECT 
        w.w_warehouse_name, 
        SUM(ws.ws_ext_sales_price) AS TotalSales, 
        SUM(ws.ws_ext_tax) AS TotalTax
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_name
)
SELECT 
    ad.ca_city, 
    ad.ca_state, 
    ad.AddressCount, 
    ad.FullAddress, 
    dd.Gender, 
    dd.MaritalStatus, 
    dd.CustomerCount, 
    sd.w_warehouse_name, 
    sd.TotalSales, 
    sd.TotalTax
FROM AddressDetails ad
FULL OUTER JOIN DemographicDetails dd ON ad.ca_state = 'CA' 
FULL OUTER JOIN SalesData sd ON sd.TotalSales > 1000 
ORDER BY 
    ad.AddressCount DESC, 
    dd.CustomerCount DESC;
