
WITH RECURSIVE Sales_Analysis AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
Top_Sellers AS (
    SELECT 
        sa.ws_item_sk,
        sa.total_sales,
        sa.order_count,
        ROW_NUMBER() OVER (ORDER BY sa.total_sales DESC) AS rank
    FROM 
        Sales_Analysis sa
    WHERE 
        sa.sales_rank <= 10
),
Customer_Income AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer c
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    cs.c_customer_sk,
    COUNT(DISTINCT cs.ws_order_number) AS total_orders,
    SUM(cs.ws_sales_price) AS total_amount,
    ci.ib_lower_bound,
    ci.ib_upper_bound
FROM 
    web_sales cs
INNER JOIN 
    Top_Sellers ts ON cs.ws_item_sk = ts.ws_item_sk
JOIN 
    Customer_Income ci ON cs.ws_bill_customer_sk = ci.c_customer_sk
WHERE 
    ci.cd_income_band_sk IS NOT NULL
GROUP BY 
    cs.c_customer_sk, ci.ib_lower_bound, ci.ib_upper_bound
HAVING 
    SUM(cs.ws_sales_price) > 500
ORDER BY 
    total_amount DESC
LIMIT 50;
