
WITH RECURSIVE sales_cte AS (
    SELECT 
        ss_sold_date_sk,
        ss_item_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS sales_count
    FROM 
        store_sales
    GROUP BY 
        ss_sold_date_sk, ss_item_sk
),
popular_items AS (
    SELECT 
        ss_item_sk,
        SUM(total_sales) AS item_sales_total,
        COUNT(DISTINCT ss_sold_date_sk) AS days_sold
    FROM 
        sales_cte
    GROUP BY 
        ss_item_sk
    HAVING 
        days_sold > 10
),
aggregated_sales AS (
    SELECT 
        si.i_item_id,
        si.i_product_name,
        COALESCE(pi.item_sales_total, 0) AS total_sales_amount,
        CASE 
            WHEN COALESCE(pi.item_sales_total, 0) > 1000 THEN 'High Seller'
            WHEN COALESCE(pi.item_sales_total, 0) BETWEEN 500 AND 1000 THEN 'Medium Seller'
            ELSE 'Low Seller'
        END AS sales_category
    FROM 
        item si
    LEFT JOIN 
        popular_items pi ON si.i_item_sk = pi.ss_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
date_analysis AS (
    SELECT 
        d.d_date,
        EXTRACT(YEAR FROM d.d_date) AS sale_year,
        EXTRACT(MONTH FROM d.d_date) AS sale_month,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_date
)
SELECT 
    ai.i_product_name,
    ai.total_sales_amount,
    ci.c_customer_id,
    ci.cd_gender,
    ci.hd_buy_potential,
    da.sale_year,
    da.sale_month,
    da.total_orders,
    da.total_profit
FROM 
    aggregated_sales ai
JOIN 
    customer_info ci ON ci.cd_income_band_sk IN (
        SELECT ib_income_band_sk 
        FROM income_band 
        WHERE ib_lower_bound <= 60000 AND ib_upper_bound > 40000
    )
CROSS JOIN 
    (SELECT MAX(sale_year) AS max_year FROM date_analysis) AS max_year_info
JOIN 
    date_analysis da ON da.sale_year = max_year_info.max_year
WHERE 
    ai.total_sales_amount > 0
ORDER BY 
    ai.total_sales_amount DESC, 
    ci.c_customer_id ASC;
