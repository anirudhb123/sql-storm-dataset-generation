
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) as sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_sk, ws.ws_sold_date_sk
), 
TopSales AS (
    SELECT 
        w.warehouse_id,
        SUM(s.total_sales) AS total_warehouse_sales
    FROM 
        SalesCTE s
    JOIN 
        warehouse w ON s.web_site_sk = w.warehouse_sk
    WHERE 
        s.sales_rank <= 5
    GROUP BY 
        w.warehouse_id
),
CustomerSegments AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    ca.ca_city,
    ts.total_warehouse_sales,
    cs.customer_count,
    cs.max_purchase_estimate,
    NULLIF(ts.total_warehouse_sales / NULLIF(cs.customer_count, 0), 0) AS avg_sales_per_customer
FROM 
    TopSales ts
JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_current_cdemo_sk IN (SELECT cd.cd_demo_sk FROM customer_demographics cd WHERE cd.cd_gender = 'M') LIMIT 1)
LEFT JOIN 
    CustomerSegments cs ON cs.cd_gender = 'M'
WHERE 
    ts.total_warehouse_sales > 10000
ORDER BY 
    ts.total_warehouse_sales DESC;
