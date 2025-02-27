
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) as rank,
        SUM(ws_sales_price * ws_quantity) OVER (PARTITION BY ws_item_sk) AS total_sales
    FROM 
        web_sales
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        hd.hd_income_band_sk
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
StoreInfo AS (
    SELECT 
        s_store_sk,
        s_store_name,
        COALESCE(SUM(ss_net_profit), 0) AS total_store_profit
    FROM 
        store 
    LEFT JOIN 
        store_sales ON store.s_store_sk = store_sales.ss_store_sk
    GROUP BY 
        s_store_sk, s_store_name
)
SELECT 
    c.c_customer_id,
    d.d_date AS sales_date,
    SUM(ws_quantity) AS total_quantity,
    AVG(ws_sales_price) AS avg_sales_price,
    MAX(ws_sales_price) AS max_sales_price,
    MIN(ws_sales_price) AS min_sales_price,
    s.total_store_profit,
    CASE 
        WHEN cd_income_band_sk IS NULL THEN 'Unknown'
        ELSE (SELECT 
                    CASE 
                        WHEN ib_upper_bound IS NULL THEN '> ' || ib_lower_bound
                        ELSE ib_lower_bound || ' - ' || ib_upper_bound 
                    END 
                FROM income_band 
                WHERE ib_income_band_sk = cd_income_band_sk) 
    END AS income_band
FROM 
    RankedSales r
JOIN 
    web_sales ws ON r.ws_item_sk = ws.ws_item_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    CustomerDemographics cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
JOIN 
    StoreInfo s ON ws.ws_warehouse_sk = s.s_store_sk
WHERE 
    d.d_year = 2023
    AND (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
GROUP BY 
    c_customer_id, d_date, s.total_store_profit, cd_income_band_sk
ORDER BY 
    c_customer_id, d_date DESC;
