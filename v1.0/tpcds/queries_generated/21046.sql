
WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid) AS total_net_paid,
        DENSE_RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_paid) DESC) AS rank_within_item
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
),
MaxQuantities AS (
    SELECT 
        rc.cs_item_sk,
        rc.total_quantity,
        CASE 
            WHEN rc.total_quantity > 100 THEN 'High'
            WHEN rc.total_quantity BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low'
        END AS quantity_category
    FROM 
        RankedSales rc
    WHERE 
        rank_within_item = 1
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        SUM(cs_total_sales) AS total_purchases
    FROM (
        SELECT 
            ss_customer_sk,
            SUM(ss_net_paid) AS cs_total_sales
        FROM 
            store_sales
        WHERE 
            ss_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
        GROUP BY 
            ss_customer_sk
    ) AS salesSummary
    JOIN customer c ON c.c_customer_sk = salesSummary.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential
    FROM 
        customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
)
SELECT DISTINCT 
    d.d_date_id,
    SUM(IFNULL(ss.ss_net_paid, 0) + COALESCE(cs.cs_ext_discount_amt, 0)) AS total_sales_with_discounts,
    cd.buy_potential,
    CASE 
        WHEN SUM(ss.ss_net_paid) > 1000 THEN 'VIP'
        WHEN SUM(ss.ss_net_paid) BETWEEN 500 AND 1000 THEN 'Regular'
        ELSE 'Occasional'
    END AS customer_status,
    MAX(mq.total_quantity) AS highest_quantity_sold,
    string_agg(DISTINCT i.i_item_id || ' - ' || i.i_item_desc) AS items_sold
FROM 
    date_dim d
LEFT JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
LEFT JOIN catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
LEFT JOIN MaxQuantities mq ON ss.ss_item_sk = mq.cs_item_sk
LEFT JOIN CustomerPurchases cp ON ss.ss_customer_sk = cp.c_customer_sk
LEFT JOIN CustomerDemographics cd ON cp.c_customer_sk = cd.cd_demo_sk
LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
WHERE 
    d.d_dow IN (6, 7) AND 
    (d.d_current_month = '1' OR d.d_current_month IS NULL) AND
    (cd.cd_gender IS NULL OR cd.cd_marital_status = 'M') AND
    (i.i_current_price < 50.00 OR mq.quantity_category = 'High')
GROUP BY 
    d.d_date_id,
    cd.buy_potential
ORDER BY 
    total_sales_with_discounts DESC
LIMIT 100;
