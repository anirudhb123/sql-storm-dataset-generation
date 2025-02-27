
WITH RECURSIVE sales_trends AS (
    SELECT 
        d.d_year,
        SUM(COALESCE(ws.ws_quantity, 0) + COALESCE(cs.cs_quantity, 0) + COALESCE(ss.ss_quantity, 0)) AS total_sales
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        d.d_year
    UNION ALL
    SELECT 
        d.d_year,
        SUM(COALESCE(ws.ws_quantity, 0) + COALESCE(cs.cs_quantity, 0) + COALESCE(ss.ss_quantity, 0)) + st.total_sales AS total_sales
    FROM 
        date_dim d
    JOIN 
        sales_trends st ON d.d_year = st.d_year + 1
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        d.d_year
), 
income_categories AS (
    SELECT 
        ib.ib_income_band_sk,
        CASE
            WHEN ib.ib_lower_bound IS NULL OR ib.ib_upper_bound IS NULL THEN 'Unknown'
            ELSE CONCAT('Income from ', ib.ib_lower_bound, ' to ', ib.ib_upper_bound)
        END AS income_range
    FROM 
        income_band ib
), 
customer_details AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
)
SELECT 
    it.income_range,
    SUM(cd.total_orders) AS total_orders,
    SUM(cd.total_profit) AS total_profit,
    AVG(cd.total_profit) AS avg_profit,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY cd.total_profit) AS median_profit,
    MAX(cd.total_profit) AS max_profit,
    MIN(cd.total_profit) AS min_profit,
    ROW_NUMBER() OVER (PARTITION BY it.income_range ORDER BY SUM(cd.total_profit) DESC) AS rank
FROM 
    income_categories it
LEFT JOIN 
    customer_details cd ON cd.c_customer_sk IS NOT NULL
GROUP BY 
    it.income_range
ORDER BY 
    total_profit DESC;
