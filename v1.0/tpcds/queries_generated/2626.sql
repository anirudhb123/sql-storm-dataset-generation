
WITH RankedSales AS (
    SELECT 
        s_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_sold,
        RANK() OVER (PARTITION BY s_store_sk ORDER BY SUM(ss_quantity) DESC) AS rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 
        (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND 
        (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        s_store_sk, 
        ss_item_sk
),
CustomerStats AS (
    SELECT 
        c_customer_sk,
        COUNT(DISTINCT ss_ticket_number) AS total_purchases,
        SUM(ss_net_paid) AS total_spent
    FROM 
        store_sales
    JOIN customer ON ss_customer_sk = c_customer_sk
    GROUP BY 
        c_customer_sk
),
TopItems AS (
    SELECT 
        r.s_store_sk,
        r.ss_item_sk,
        r.total_sold,
        cs.total_purchases,
        cs.total_spent,
        COALESCE(cs.total_purchases, 0) AS adjusted_purchases,
        CASE 
            WHEN cs.total_spent IS NULL THEN 'No Purchases'
            ELSE 'Purchased'
        END AS purchase_status
    FROM 
        RankedSales r
    LEFT JOIN 
        CustomerStats cs ON r.s_store_sk = cs.c_customer_sk
    WHERE 
        r.rank <= 10
),
IncomeDistribution AS (
    SELECT 
        hd_income_band_sk,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        household_demographics hd
    JOIN 
        customer c ON hd.hd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        hd_income_band_sk
)
SELECT 
    t.w_warehouse_id,
    ti.ss_item_sk,
    ti.total_sold,
    ti.total_purchases,
    ti.total_spent,
    CASE 
        WHEN ti.adjusted_purchases > 0 THEN 'High Engagement'
        ELSE 'Low Engagement'
    END AS engagement_level,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    id.customer_count
FROM 
    TopItems ti
JOIN warehouse t ON ti.s_store_sk = t.w_warehouse_sk
LEFT JOIN income_band ib ON ti.adjusted_purchases BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
LEFT JOIN IncomeDistribution id ON ib.ib_income_band_sk = id.hd_income_band_sk
ORDER BY 
    ti.total_sold DESC, 
    ti.total_spent DESC;
