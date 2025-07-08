
WITH SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        1 AS level
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    
    UNION ALL
    
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_sales_price) AS total_sales,
        level + 1 
    FROM 
        catalog_sales
    JOIN 
        SalesCTE ON SalesCTE.ws_item_sk = cs_item_sk
    GROUP BY 
        cs_item_sk, level
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_net_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, hd.hd_buy_potential
),
MonthlySales AS (
    SELECT 
        d.d_year,
        d.d_moy,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year, d.d_moy
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    SUM(ci.total_net_profit) AS customer_net_profit,
    ms.total_sales AS monthly_sales,
    bi.ib_upper_bound,
    ROW_NUMBER() OVER (PARTITION BY ci.cd_gender ORDER BY SUM(ci.total_net_profit) DESC) AS sales_rank
FROM 
    CustomerInfo ci 
JOIN 
    MonthlySales ms ON ci.c_customer_id IS NOT NULL
JOIN 
    income_band bi ON (ci.total_net_profit BETWEEN bi.ib_lower_bound AND bi.ib_upper_bound)
GROUP BY 
    ci.c_customer_id, ci.cd_gender, ci.cd_marital_status, ms.total_sales, bi.ib_upper_bound
HAVING 
    SUM(ci.total_net_profit) > 1000
ORDER BY 
    customer_net_profit DESC
LIMIT 100;
