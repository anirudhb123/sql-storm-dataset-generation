
WITH RECURSIVE sales_data AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid) DESC) AS rank_sales
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        ss_store_sk, ss_item_sk
),
top_stores AS (
    SELECT 
        sd.ss_store_sk,
        SUM(sd.total_net_paid) AS total_net_paid_store,
        COUNT(DISTINCT sd.ss_item_sk) AS unique_items_sold
    FROM 
        sales_data sd
    WHERE 
        sd.rank_sales <= 10
    GROUP BY 
        sd.ss_store_sk
),
customers_with_income AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(DISTINCT s.ss_ticket_number) AS total_store_purchases
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    WHERE 
        c.c_first_shipto_date_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, ib.ib_lower_bound, ib.ib_upper_bound
),
composite_data AS (
    SELECT 
        ts.ss_store_sk,
        ts.total_net_paid_store,
        ts.unique_items_sold,
        cwi.cd_gender,
        cwi.cd_marital_status,
        cwi.total_store_purchases,
        CASE 
            WHEN cwi.total_store_purchases IS NULL THEN 'No Purchases'
            ELSE CAST(cwi.ib_lower_bound AS CHAR) || ' - ' || CAST(cwi.ib_upper_bound AS CHAR)
        END AS income_band_range
    FROM 
        top_stores ts
    LEFT JOIN 
        customers_with_income cwi ON ts.ss_store_sk = cwi.c_customer_sk % 10
)
SELECT 
    cd.ss_store_sk,
    cd.total_net_paid_store,
    cd.unique_items_sold,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(cd.income_band_range, 'Unknown') AS income_band,
    COUNT(*) OVER (PARTITION BY cd.cd_gender, cd.income_band_range) AS gender_income_count,
    AVG(cd.total_net_paid_store) OVER (PARTITION BY cd.income_band_range) AS avg_sales_per_income_band
FROM 
    composite_data cd
WHERE 
    cd.total_net_paid_store > 1000
ORDER BY 
    cd.total_net_paid_store DESC, cd.cd_gender;
