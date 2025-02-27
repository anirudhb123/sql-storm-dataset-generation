
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451545 AND 2451545 + 30  -- Sample Date Range
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN 2451545 AND 2451545 + 30
    GROUP BY 
        cs_item_sk
),
CustomerCTE AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        SUM(s.total_sales) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        (SELECT ws_item_sk, SUM(ws_net_profit) AS total_sales FROM web_sales WHERE ws_sold_date_sk > 2451545 GROUP BY ws_item_sk) ws ON c.c_customer_sk = ws.ws_item_sk  
    LEFT JOIN 
        (SELECT cs_item_sk, SUM(cs_net_profit) AS total_sales FROM catalog_sales WHERE cs_sold_date_sk > 2451545 GROUP BY cs_item_sk) cs ON c.c_customer_sk = cs.cs_item_sk
    GROUP BY 
        c.c_customer_sk, 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
),
DateSummary AS (
    SELECT 
        d.d_year,
        d.d_moy,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        SUM(ws.ws_net_profit) AS total_sales
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        d.d_year, d.d_moy
)
SELECT 
    dc.d_year,
    dc.d_moy,
    dc.unique_customers,
    dc.total_sales,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_purchase_estimate,
    COALESCE(s.total_profit, 0) AS total_profit
FROM 
    DateSummary dc
JOIN 
    CustomerCTE c ON dc.unique_customers = c.c_customer_sk
LEFT JOIN 
    SalesCTE s ON c.c_customer_sk = s.ws_item_sk
WHERE 
    (c.cd_marital_status = 'M' OR c.cd_gender = 'F') AND 
    (s.total_sales > 1000 OR s.total_quantity > 10)
ORDER BY 
    dc.d_year DESC, dc.d_moy ASC;
