
WITH sales_data AS (
    SELECT 
        ss.store_sk,
        SUM(ss.ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.customer_sk) AS unique_customers,
        AVG(ss.ext_discount_amt) AS avg_discount,
        SUM(ss.net_profit) AS total_profit
    FROM 
        store_sales ss
    JOIN 
        date_dim d ON ss.sold_date_sk = d.d_date_sk
    JOIN 
        store s ON ss.store_sk = s.s_store_sk
    WHERE 
        d.d_year = 2023 
        AND s.s_state = 'CA'
    GROUP BY 
        ss.store_sk
),
promotion_data AS (
    SELECT 
        p.promo_sk,
        p.promo_name,
        COUNT(cs.order_number) AS total_orders,
        SUM(cs.ext_sales_price) AS total_sales,
        AVG(cs.ext_discount_amt) AS avg_discount
    FROM 
        promotion p
    JOIN 
        catalog_sales cs ON p.promo_sk = cs.promo_sk
    WHERE 
        p.promo_name IS NOT NULL
    GROUP BY 
        p.promo_sk, p.promo_name
),
final_report AS (
    SELECT 
        sd.store_sk,
        sd.total_sales AS store_sales,
        sd.unique_customers,
        sd.avg_discount AS store_avg_discount,
        pd.promo_name,
        pd.total_orders,
        pd.total_sales AS promo_sales,
        pd.avg_discount AS promo_avg_discount
    FROM 
        sales_data sd
    LEFT JOIN 
        promotion_data pd ON sd.store_sk = pd.promo_sk
)
SELECT 
    store_sk,
    SUM(store_sales) AS total_store_sales,
    SUM(unique_customers) AS total_unique_customers,
    AVG(store_avg_discount) AS overall_avg_discount,
    SUM(total_orders) AS total_promo_orders,
    SUM(promo_sales) AS total_promo_sales
FROM 
    final_report
GROUP BY 
    store_sk
ORDER BY 
    total_store_sales DESC
LIMIT 10;
