
WITH CTE_Customer_Sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(ws.ws_item_sk) AS total_items,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM customer AS c
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender IS NOT NULL AND 
          cd.cd_credit_rating IN ('Good', 'Fair') 
          AND c.c_birth_year BETWEEN 1980 AND 1990 
    GROUP BY c.c_customer_id
),
CTE_Income_Bands AS (
    SELECT 
        hd.hd_income_band_sk,
        CASE 
            WHEN ib.ib_lower_bound IS NULL THEN 'Unknown'
            WHEN ib.ib_upper_bound IS NULL THEN 'Unknown'
            ELSE CONCAT(ib.ib_lower_bound, '-', ib.ib_upper_bound)
        END AS income_range
    FROM household_demographics AS hd
    LEFT JOIN income_band AS ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    ccs.c_customer_id,
    ccs.total_sales,
    ccs.total_orders,
    ccs.total_items,
    COALESCE(inb.income_range, 'No Income Data') AS income_band,
    CASE 
        WHEN ccs.total_sales > 1000 THEN 'High Value Customer'
        WHEN ccs.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM CTE_Customer_Sales AS ccs
LEFT JOIN CTE_Income_Bands AS inb ON REPLACE(ccs.c_customer_id, 'Customer_', '')::integer = inb.hd_income_band_sk
WHERE ccs.sales_rank <= 10
ORDER BY total_sales DESC
LIMIT 20;
