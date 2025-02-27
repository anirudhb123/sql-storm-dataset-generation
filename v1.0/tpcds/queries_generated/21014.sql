
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_id ORDER BY ws.ws_net_profit DESC) AS SalesRank
    FROM customer AS c
    JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_ext_sales_price > 100
),
TopCustomerSales AS (
    SELECT 
        r.c_customer_id,
        r.c_first_name,
        r.c_last_name,
        r.ws_order_number,
        r.ws_ext_sales_price,
        r.ws_net_profit
    FROM RankedSales r
    WHERE r.SalesRank <= 3
),
CustomerDemographicInfo AS (
    SELECT 
        cd_cdemo_sk,
        cd_marital_status,
        cd_gender,
        CASE 
            WHEN cd_purchase_estimate IS NULL THEN 0
            ELSE cd_purchase_estimate
        END AS adjusted_purchase_estimate
    FROM customer_demographics
    WHERE cd_gender IS NOT NULL
),
FinalSalesData AS (
    SELECT 
        t.c_customer_id,
        t.ws_order_number,
        SUM(t.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT t.ws_order_number) AS order_count,
        cd.adjusted_purchase_estimate,
        CASE
            WHEN AVG(cd.adjusted_purchase_estimate) > 500 THEN 'High'
            WHEN AVG(cd.adjusted_purchase_estimate) BETWEEN 200 AND 500 THEN 'Medium'
            ELSE 'Low'
        END AS spending_category
    FROM TopCustomerSales t
    LEFT JOIN CustomerDemographicInfo cd ON t.c_customer_id = cd.cd_cdemo_sk
    GROUP BY t.c_customer_id, cd.adjusted_purchase_estimate
)
SELECT 
    f.c_customer_id,
    f.total_sales,
    f.order_count,
    f.spending_category,
    CASE 
        WHEN f.spending_category = 'High' THEN 'Promotional Email'
        WHEN f.spending_category = 'Medium' THEN 'Loyalty Discount'
        ELSE 'Standard Offer'
    END AS suggested_offer,
    COALESCE(f.total_sales / NULLIF(f.order_count, 0), 0) AS average_sales_per_order
FROM FinalSalesData f
WHERE f.total_sales IS NOT NULL
ORDER BY f.total_sales DESC;
