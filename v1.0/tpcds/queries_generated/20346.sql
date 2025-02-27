
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ws.bill_customer_sk AS customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank,
        cd_gender,
        cd_marital_status,
        d_year,
        WINDOW_RANGE AS ws_date_range
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.bill_customer_sk, cd_gender, cd_marital_status, d_year
    HAVING 
        SUM(ws.ws_net_paid) > (SELECT AVG(ws2.ws_net_paid) FROM web_sales ws2 WHERE ws2.ws_bill_customer_sk = ws.bill_customer_sk)
    UNION ALL
    SELECT 
        customer_sk,
        total_sales * 1.10 AS total_sales,
        rank,
        cd_gender,
        cd_marital_status,
        d_year + 1,
        ws_date_range
    FROM 
        sales_hierarchy
    WHERE 
        rank <= 5
),
customer_incomes AS (
    SELECT 
        c.c_customer_id,
        ib.ib_income_band_sk,
        SUM(case when ws.ws_net_paid > 50 THEN ws.ws_net_paid END) AS high_spend,
        COUNT(*) AS transaction_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        ib.ib_lower_bound IS NOT NULL OR ib.ib_upper_bound IS NOT NULL
    GROUP BY 
        c.c_customer_id, ib.ib_income_band_sk
),
sales_analysis AS (
    SELECT 
        ci.c_customer_id,
        SUM(sh.total_sales) AS total_sales,
        MAX(sh.rank) AS max_rank,
        COALESCE(AVG(ci.high_spend), 0) AS average_high_spend,
        SUM(CASE 
                WHEN ci.transaction_count > 1 THEN 1 
                ELSE 0 
            END) AS multi_transaction_customers
    FROM 
        customer_incomes ci
    JOIN 
        sales_hierarchy sh ON ci.c_customer_id = sh.customer_sk
    GROUP BY 
        ci.c_customer_id
)
SELECT 
    sa.c_customer_id,
    sa.total_sales,
    sa.max_rank,
    sa.average_high_spend,
    sa.multi_transaction_customers
FROM 
    sales_analysis sa
WHERE 
    sa.total_sales > (
        SELECT 
            AVG(total_sales) 
        FROM 
            sales_analysis
    ) OR EXISTS (
        SELECT 1 
        FROM web_returns wr 
        WHERE 
            wr.wr_returning_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_customer_id = sa.c_customer_id) 
            AND wr.wr_return_quantity > (
                SELECT AVG(wr2.wr_return_quantity) FROM web_returns wr2 WHERE wr2.wr_returning_customer_sk = wr.wr_returning_customer_sk
            )
    )
ORDER BY 
    sa.total_sales DESC
LIMIT 100 OFFSET 10;
