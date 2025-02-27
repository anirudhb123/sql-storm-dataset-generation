
WITH SalesData AS (
    SELECT 
        s.s_store_id,
        c.c_city,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        store s
    JOIN 
        web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        s.s_store_id, c.c_city
),
DemographicsData AS (
    SELECT 
        c.c_city,
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_city, cd.cd_gender
)
SELECT 
    s.store_id,
    s.city,
    COALESCE(sd.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(sd.total_sales, 0.00) AS total_sales,
    COALESCE(sd.avg_net_profit, 0.00) AS avg_net_profit,
    COALESCE(dd.customer_count, 0) AS customer_count,
    COALESCE(dd.avg_purchase_estimate, 0.00) AS avg_purchase_estimate
FROM 
    (SELECT DISTINCT s_store_id AS store_id, s_city AS city FROM store) s
LEFT JOIN 
    SalesData sd ON s.store_id = sd.s_store_id
LEFT JOIN 
    DemographicsData dd ON s.city = dd.c_city
ORDER BY 
    total_sales DESC, customer_count DESC;
