
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_list_price) AS avg_list_price,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        ws.web_site_id, d.d_year, d.d_month_seq
)
SELECT 
    sd.web_site_id,
    sd.total_sales,
    sd.total_orders,
    sd.avg_list_price,
    sd.avg_net_profit,
    cd.cd_gender,
    cd.cd_marital_status,
    ca.ca_country
FROM 
    SalesData sd
JOIN 
    customer c ON c.c_customer_id IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales)
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    sd.total_sales > 10000
ORDER BY 
    sd.total_sales DESC
LIMIT 10;
