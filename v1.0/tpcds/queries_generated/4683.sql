
WITH TotalSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F' AND cd.cd_marital_status = 'M' 
    GROUP BY ws.web_site_sk
),
SalesByRegion AS (
    SELECT 
        ca.ca_state,
        SUM(ts.total_sales) AS regional_sales,
        SUM(ts.order_count) AS regional_orders
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN TotalSales ts ON c.c_current_addr_sk IS NOT NULL
    GROUP BY ca.ca_state
),
TopRegions AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY regional_sales DESC) as region_rank
    FROM SalesByRegion
)
SELECT 
    tr.ca_state AS state,
    tr.regional_sales,
    tr.regional_orders,
    COALESCE(ss.sm_code, 'N/A') AS shipping_type,
    CASE 
        WHEN tr.regional_sales > 100000 THEN 'High Value'
        WHEN tr.regional_sales BETWEEN 50000 AND 100000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS sales_category
FROM TopRegions tr
LEFT JOIN ship_mode ss ON tr.region_rank <= 5 AND ss.sm_ship_mode_sk = ANY(SELECT sm_ship_mode_sk FROM store_sales ss WHERE ss.ss_store_sk = 1) 
WHERE tr.region_rank <= 10
ORDER BY tr.regional_sales DESC;
