
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity_sold, 
        SUM(ws_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
TopItems AS (
    SELECT 
        r.ws_item_sk, 
        r.total_quantity_sold, 
        r.total_revenue,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand
    FROM 
        RankedSales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.rank <= 10
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_gender, 
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
), 
SalesByDemographics AS (
    SELECT 
        t.cd_gender,
        t.cd_marital_status,
        SUM(s.total_revenue) AS total_sales
    FROM 
        CustomerDemographics t
    JOIN 
        web_sales w ON w.ws_bill_customer_sk IN (SELECT c.c_customer_sk FROM customer c WHERE c.c_current_cdemo_sk IN (SELECT cd.cd_demo_sk FROM customer_demographics cd WHERE cd.cd_gender = t.cd_gender AND cd.cd_marital_status = t.cd_marital_status))
    JOIN 
        TopItems ti ON w.ws_item_sk = ti.ws_item_sk
    GROUP BY 
        t.cd_gender, t.cd_marital_status
)
SELECT 
    a.cd_gender,
    a.cd_marital_status,
    COALESCE(b.total_sales, 0) AS total_sales,
    COALESCE(b.total_sales / NULLIF(a.customer_count, 0), 0) AS average_sales_per_customer
FROM 
    CustomerDemographics a
LEFT JOIN 
    SalesByDemographics b ON a.cd_gender = b.cd_gender AND a.cd_marital_status = b.cd_marital_status
ORDER BY 
    a.cd_gender, a.cd_marital_status;
