
WITH RankedReturns AS (
    SELECT 
        sr_returning_customer_sk, 
        sr_item_sk,
        COUNT(sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity,
        RANK() OVER (PARTITION BY sr_returning_customer_sk ORDER BY SUM(sr_return_amt) DESC) AS return_rank
    FROM store_returns 
    GROUP BY sr_returning_customer_sk, sr_item_sk
),
HighValueReturns AS (
    SELECT 
        r.returning_customer_sk, 
        r.item_sk,
        r.return_count,
        r.total_return_amount,
        r.total_return_quantity,
        CASE 
            WHEN r.total_return_amount > 500 THEN 'High Value'
            ELSE 'Standard Value'
        END AS return_value_category
    FROM RankedReturns r
    WHERE r.return_rank <= 3
),
SalesData AS (
    SELECT 
        ws.ws_ship_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM web_sales ws
    GROUP BY ws.ws_ship_customer_sk
),
CombinedData AS (
    SELECT 
        s.ship_customer_sk AS customer_id,
        COALESCE(SUM(hvr.total_return_amount), 0) AS total_return_amount,
        COALESCE(sd.total_sales, 0) AS total_sales,
        (COALESCE(SUM(hvr.total_return_amount), 0) - COALESCE(sd.total_sales, 0)) AS net_amount,
        CASE 
            WHEN COALESCE(SUM(hvr.total_return_amount), 0) > COALESCE(sd.total_sales, 0) THEN 'High Return Rate'
            ELSE 'Normal'
        END AS return_rate_status
    FROM HighValueReturns hvr
    FULL OUTER JOIN SalesData sd ON hvr.returning_customer_sk = sd.ship_customer_sk
    GROUP BY s.ship_customer_sk
)
SELECT 
    cd.c_customer_id,
    cd.c_first_name,
    cd.c_last_name,
    cd.c_email_address,
    cd.c_preferred_cust_flag,
    cd.c_birth_day,
    cd.c_birth_month,
    MAX(cd.c_birth_year) AS birth_year,
    SUM(CASE WHEN cd.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_customers,
    SUM(CASE WHEN cd.c_birth_country IS NOT NULL THEN 1 ELSE 0 END) AS country_known_customers,
    cd.c_birth_country,
    db.total_sales,
    db.total_return_amount,
    db.net_amount,
    db.return_rate_status
FROM customer cd
LEFT JOIN CombinedData db ON cd.c_customer_sk = db.customer_id
GROUP BY 
    cd.c_customer_id,
    cd.c_first_name,
    cd.c_last_name,
    cd.c_email_address,
    cd.c_preferred_cust_flag,
    cd.c_birth_day,
    cd.c_birth_month,
    cd.c_birth_country
HAVING 
    SUM(db.net_amount) > 0 OR COUNT(cd.c_birth_country) IS NULL 
ORDER BY 
    db.total_return_amount DESC, 
    cd.c_last_name ASC, 
    cd.c_first_name ASC;
