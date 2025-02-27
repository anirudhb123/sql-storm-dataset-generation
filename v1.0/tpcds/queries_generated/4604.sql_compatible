
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_profit,
        CASE 
            WHEN SUM(ss.ss_net_profit) IS NULL THEN 'No Sales'
            WHEN SUM(ss.ss_net_profit) > 1000 THEN 'High Value Customer'
            ELSE 'Regular Customer' 
        END AS customer_value
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
DateSales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(ss.ss_net_profit) AS store_profit
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        d.d_date
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_sales,
    cs.total_profit,
    ds.d_date,
    COALESCE(ds.web_profit, 0) AS web_profit,
    COALESCE(ds.catalog_profit, 0) AS catalog_profit,
    COALESCE(ds.store_profit, 0) AS store_profit,
    cs.customer_value,
    CASE 
        WHEN cs.total_sales > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS customer_status
FROM 
    CustomerStats cs
LEFT JOIN 
    DateSales ds ON cs.c_customer_sk = (SELECT ws.ws_ship_customer_sk FROM web_sales ws WHERE ws.ws_sold_date_sk = ds.d_date_sk LIMIT 1)
WHERE 
    cs.purchase_rank <= 10 
    AND (cs.cd_marital_status = 'M' OR cs.total_profit > 500)
ORDER BY 
    cs.total_profit DESC, 
    cs.c_last_name, 
    cs.c_first_name;
