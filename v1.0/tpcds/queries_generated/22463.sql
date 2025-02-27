
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        (cd.cd_marital_status = 'M' OR cd.cd_marital_status = 'S')
        AND cd.cd_purchase_estimate IS NOT NULL
        AND (c.c_birth_year > 1970 OR c.c_birth_country IS NULL)
    GROUP BY 
        ws.web_site_id
),
TopSites AS (
    SELECT 
        web_site_id
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
),
SalesCosts AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_wholesale_cost) AS total_cost,
        SUM(cs.cs_ext_discount_amt) AS total_discount
    FROM 
        catalog_sales cs
    JOIN 
        TopSites ts ON cs.cs_ship_mode_sk = ts.web_site_id
    GROUP BY 
        cs.cs_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    sc.total_sales,
    sc.total_cost,
    sc.total_sales - sc.total_cost - COALESCE(sc.total_discount, 0) AS net_profit,
    CASE 
        WHEN (sc.total_sales - sc.total_cost) < 0 THEN 'Loss'
        WHEN (sc.total_sales - sc.total_cost) BETWEEN 1 AND 100 THEN 'Low Profit'
        ELSE 'High Profit'
    END AS profit_type
FROM 
    item i
LEFT JOIN 
    SalesCosts sc ON i.i_item_sk = sc.cs_item_sk
WHERE 
    i.i_current_price IS NOT NULL
    AND (i.i_container IS NULL OR i.i_container = 'BOX')
ORDER BY 
    net_profit DESC,
    i.i_item_desc ASC;
