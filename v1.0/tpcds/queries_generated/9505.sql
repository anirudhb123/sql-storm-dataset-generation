
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023 
        AND cd.cd_gender = 'F'
    GROUP BY 
        ws.web_site_id
),
AddressData AS (
    SELECT 
        ca.ca_country,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        ca.ca_country
),
WarehouseData AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    WHERE 
        w.w_country = 'USA'
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    sd.web_site_id,
    sd.total_quantity,
    sd.total_sales,
    sd.total_orders,
    ad.ca_country,
    ad.unique_customers,
    wd.w_warehouse_id,
    wd.total_profit
FROM 
    SalesData sd
JOIN 
    AddressData ad ON sd.web_site_id = ad.unique_customers
JOIN 
    WarehouseData wd ON sd.total_orders = wd.total_profit
ORDER BY 
    sd.total_sales DESC, 
    ad.unique_customers ASC;
