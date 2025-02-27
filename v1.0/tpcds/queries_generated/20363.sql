
WITH address_performance AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS addr_rank
    FROM
        customer_address
    WHERE
        ca_city IS NOT NULL
),
customer_performance AS (
    SELECT
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        SUM(CASE WHEN cd_purchase_estimate IS NULL THEN 0 ELSE cd_purchase_estimate END) AS total_purchase_estimate,
        DENSE_RANK() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS purchase_rank
    FROM
        customer
    JOIN
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY
        c_customer_sk, cd_gender, cd_marital_status
    HAVING
        COUNT(*) > 1
),
sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(CASE WHEN ws_sales_price IS NULL THEN 0 ELSE ws_sales_price END) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        MAX(ws_sales_price) AS max_sale,
        MIN(ws_sales_price) AS min_sale
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
sales_distribution AS (
    SELECT 
        ws_bill_customer_sk,
        NTILE(4) OVER (ORDER BY total_sales DESC) AS sales_quartile
    FROM 
        sales_summary
),
final_summary AS (
    SELECT
        c.c_customer_sk,
        c.cd_gender,
        a.full_address,
        ss.total_sales,
        sd.sales_quartile
    FROM
        customer_performance c
    LEFT JOIN
        address_performance a ON a.addr_rank = 1
    JOIN
        sales_summary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN
        sales_distribution sd ON c.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT
    f.c_customer_sk,
    f.cd_gender,
    f.full_address,
    f.total_sales,
    CASE 
        WHEN f.sales_quartile IS NULL THEN 'No Sales Data' 
        ELSE CAST(f.sales_quartile AS VARCHAR)
    END AS sales_quartile,
    COALESCE(f.cd_marital_status, 'Unknown') AS marital_status
FROM
    final_summary f
JOIN
    (SELECT DISTINCT cd_gender FROM customer_demographics WHERE cd_marital_status = 'M') AS eligible_customers
ON
    f.cd_gender = eligible_customers.cd_gender
WHERE
    f.total_sales > (SELECT AVG(total_sales) FROM sales_summary) + 1000
ORDER BY
    f.total_sales DESC
LIMIT 10;
