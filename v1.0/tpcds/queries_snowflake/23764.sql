
WITH CustomerSales AS (
    SELECT 
        C.c_customer_sk,
        C.c_customer_id,
        SUM(COALESCE(WS.ws_sales_price, 0) - COALESCE(WS.ws_ext_discount_amt, 0)) AS total_sales,
        COUNT(DISTINCT WS.ws_order_number) AS order_count
    FROM 
        customer C
    LEFT JOIN web_sales WS ON C.c_customer_sk = WS.ws_bill_customer_sk
    GROUP BY 
        C.c_customer_sk, C.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        CD.cd_demo_sk,
        CD.cd_gender,
        CD.cd_marital_status,
        CD.cd_purchase_estimate,
        CD.cd_credit_rating,
        CASE 
            WHEN CD.cd_purchase_estimate IS NULL THEN 'Unknown' 
            WHEN CD.cd_purchase_estimate < 1000 THEN 'Low' 
            WHEN CD.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium' 
            ELSE 'High'
        END AS purchase_level
    FROM 
        customer_demographics CD
),
ReturnSummary AS (
    SELECT 
        SR.sr_customer_sk,
        COUNT(SR.sr_returned_date_sk) AS return_count,
        SUM(SR.sr_return_amt) AS total_return_amount,
        SUM(SR.sr_return_quantity) AS total_return_quantity
    FROM 
        store_returns SR
    GROUP BY 
        SR.sr_customer_sk
),
CombinedData AS (
    SELECT 
        CS.c_customer_sk,
        CS.c_customer_id,
        CD.cd_gender,
        CD.cd_marital_status,
        CD.purchase_level,
        CS.total_sales,
        CS.order_count,
        COALESCE(RS.return_count, 0) AS return_count,
        COALESCE(RS.total_return_amount, 0) AS total_return_amount
    FROM 
        CustomerSales CS
    JOIN CustomerDemographics CD ON CS.c_customer_sk = CD.cd_demo_sk
    LEFT JOIN ReturnSummary RS ON CS.c_customer_sk = RS.sr_customer_sk
)
SELECT 
    CD.c_customer_id,
    CD.cd_gender,
    CD.cd_marital_status,
    CD.purchase_level,
    CD.total_sales,
    CD.order_count,
    CD.return_count,
    CD.total_return_amount,
    S.s_store_name,
    SM.sm_type,
    CASE 
        WHEN CD.total_sales > 1000 THEN 'VIP' 
        ELSE 'Regular' 
    END AS customer_tier
FROM 
    CombinedData CD
JOIN store S ON CD.c_customer_sk = S.s_store_sk
LEFT JOIN ship_mode SM ON SM.sm_ship_mode_sk = (
    SELECT 
        SM2.sm_ship_mode_sk 
    FROM 
        web_sales WS2 
    JOIN ship_mode SM2 ON WS2.ws_ship_mode_sk = SM2.sm_ship_mode_sk 
    WHERE 
        WS2.ws_bill_customer_sk = CD.c_customer_sk 
    FETCH FIRST 1 ROWS ONLY
)
WHERE 
    CD.total_sales > (SELECT AVG(total_sales) FROM CombinedData) 
    AND (CD.return_count IS NULL OR CD.return_count < 5)
ORDER BY 
    CD.total_sales DESC, CD.c_customer_id;
