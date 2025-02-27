
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 365
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        CASE 
            WHEN cd.cd_credit_rating IS NULL THEN 'Unknown'
            ELSE cd.cd_credit_rating 
        END AS credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
HighValueOrders AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_sales,
        COUNT(*) AS order_count
    FROM 
        SalesData sd
    WHERE 
        sd.price_rank <= 5
    GROUP BY 
        sd.ws_item_sk
    HAVING 
        COUNT(*) > 2
),
HighIncomeCustomers AS (
    SELECT 
        h.hd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers
    FROM 
        household_demographics h
    JOIN 
        customer c ON h.hd_demo_sk = c.c_current_hdemo_sk 
    WHERE 
        h.hd_income_band_sk IN (SELECT ib_income_band_sk FROM income_band WHERE ib_lower_bound >= 50000)
    GROUP BY 
        h.hd_demo_sk
)
SELECT 
    cu.c_customer_sk,
    cu.cd_gender,
    SUM(hvo.total_sales) AS total_sales_from_high_value_orders,
    SUM(cu.purchase_estimate) AS total_purchase_estimate,
    AVG(SD.ws_net_profit) AS avg_profit,
    CASE 
        WHEN SUM(hvo.total_sales) IS NULL THEN 'No Sales'
        ELSE 'Has Sales'
    END AS sales_status
FROM 
    CustomerData cu
JOIN 
    HighValueOrders hvo ON cu.c_customer_sk = hvo.ws_item_sk
LEFT JOIN 
    SalesData SD ON hvo.ws_item_sk = SD.ws_item_sk
LEFT JOIN 
    HighIncomeCustomers hic ON hic.hd_demo_sk = cu.c_current_hdemo_sk
WHERE 
    cu.cd_gender = 'F' 
    AND (cu.purchase_estimate > 300 OR hic.total_customers IS NULL)
GROUP BY 
    cu.c_customer_sk, 
    cu.cd_gender
ORDER BY 
    total_sales_from_high_value_orders DESC, 
    cu.cd_gender;
