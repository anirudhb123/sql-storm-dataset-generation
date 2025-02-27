
WITH RankedSales AS (
    SELECT 
        ws_web_site_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws_web_site_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451545 AND 2451546 -- Example date range
    GROUP BY 
        ws_web_site_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        MAX(cd_purchase_estimate) AS purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status, cd_education_status
),
TopWarehouses AS (
    SELECT 
        w_warehouse_sk, 
        w_warehouse_name, 
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w_warehouse_sk, w_warehouse_name
    ORDER BY 
        order_count DESC
    LIMIT 5
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    rd.total_sales,
    rd.total_orders,
    tw.warehouse_name
FROM 
    customer cs
JOIN 
    customer_demographics cd ON cs.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    RankedSales rd ON cs.c_customer_sk = rd.ws_web_site_sk
JOIN 
    TopWarehouses tw ON rd.ws_web_site_sk = tw.w_warehouse_sk
WHERE 
    cd.purchase_estimate > 50000 
    AND rd.sales_rank <= 10
ORDER BY 
    rd.total_sales DESC, 
    cs.c_last_name;
