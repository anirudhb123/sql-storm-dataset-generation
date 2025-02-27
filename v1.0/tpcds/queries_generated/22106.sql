
WITH RECURSIVE sales_summary AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_profit) DESC) AS rn
    FROM catalog_sales
    GROUP BY cs_item_sk
), 
customer_info AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        district_income.hd_income_band_sk,
        CASE 
            WHEN cd_marital_status = 'M' THEN 'Married'
            WHEN cd_marital_status = 'S' THEN 'Single'
            ELSE 'Unknown'
        END AS marital_status
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    LEFT JOIN household_demographics district_income ON cd_demo_sk = district_income.hd_demo_sk
), 
item_details AS (
    SELECT 
        i_item_sk,
        i_product_name,
        i_brand,
        i_current_price,
        ROW_NUMBER() OVER (PARTITION BY i_brand ORDER BY i_current_price DESC) AS rank_price
    FROM item
), 
sales_with_details AS (
    SELECT 
        s.cs_item_sk,
        sum(s.cs_net_profit) AS total_net_profit,
        sum(s.cs_quantity) AS total_quantity,
        COUNT(DISTINCT s.cs_order_number) AS order_count,
        i.i_product_name,
        i.i_brand,
        cd.cd_gender,
        cd.marital_status
    FROM catalog_sales s
    JOIN item_details i ON s.cs_item_sk = i.i_item_sk
    LEFT JOIN customer_info cd ON s.cs_bill_customer_sk = cd.c_customer_sk
    GROUP BY s.cs_item_sk, i.i_product_name, i.i_brand, cd.cd_gender, cd.marital_status
)
SELECT 
    sd.i_product_name,
    sd.i_brand,
    SUM(sd.total_quantity) AS total_sales_quantity,
    SUM(sd.total_net_profit) AS total_sales_profit,
    COUNT(DISTINCT sd.order_count) AS unique_orders,
    COALESCE(cd.gender_counts, 0) AS female_count,
    COALESCE(cd.male_count, 0) AS male_count,
    CASE 
        WHEN SUM(sd.total_net_profit) > 1000 THEN 'High Profit'
        WHEN SUM(sd.total_net_profit) BETWEEN 500 AND 1000 THEN 'Moderate Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM sales_with_details sd
LEFT JOIN (
    SELECT 
        sd.i_product_name,
        SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count
    FROM sales_with_details sd
    JOIN customer_info ci ON sd.cs_bill_customer_sk = ci.c_customer_sk
    GROUP BY sd.i_product_name
) cd ON sd.i_product_name = cd.i_product_name
GROUP BY sd.i_product_name, sd.i_brand
HAVING SUM(sd.total_quantity) > 0
ORDER BY total_sales_profit DESC
LIMIT 10;
