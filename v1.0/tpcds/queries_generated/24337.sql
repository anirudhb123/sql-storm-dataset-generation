
WITH RecursiveSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        CASE 
            WHEN cd_purchase_estimate IS NULL THEN 0 
            ELSE cd_purchase_estimate 
        END AS purchase_estimate
    FROM 
        customer_demographics
    WHERE 
        cd_gender IN ('M', 'F')
),
HighSpenders AS (
    SELECT 
        cs.bill_customer_sk,
        cs.total_sales,
        CASE 
            WHEN cd.purchase_estimate > 5000 THEN 'High'
            WHEN cd.purchase_estimate BETWEEN 3000 AND 5000 THEN 'Medium'
            ELSE 'Low'
        END AS spending_category
    FROM 
        RecursiveSales cs
    JOIN 
        CustomerDemographics cd ON cs.ws_bill_customer_sk = cd.cd_demo_sk
    WHERE 
        cs.sales_rank <= 10
),
WarehouseInfo AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        warehouse w
    LEFT JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
CustomerLocation AS (
    SELECT 
        ca.ca_address_sk,
        c.c_customer_id,
        ca.ca_city,
        COUNT(DISTINCT w.w_warehouse_id) AS warehouse_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        warehouse w ON ca.ca_city = w.w_city
    GROUP BY 
        ca.ca_address_sk, c.c_customer_id, ca.ca_city
)
SELECT 
    cs.c_customer_id,
    cl.ca_city,
    hs.spending_category,
    wi.total_orders,
    wi.total_net_profit
FROM 
    HighSpenders hs
JOIN 
    customer c ON hs.bill_customer_sk = c.c_customer_sk
LEFT JOIN 
    CustomerLocation cl ON c.c_customer_sk = cl.c_customer_id
JOIN 
    WarehouseInfo wi ON cl.warehouse_count > 0
WHERE 
    (wi.total_net_profit IS NOT NULL OR wi.total_net_profit < 10000) 
    AND cl.warehouse_count BETWEEN 1 AND 5
ORDER BY 
    cs.total_sales DESC, cl.ca_city;
