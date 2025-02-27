
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Unknown'
        END AS gender,
        cd_marital_status, 
        cd_purchase_estimate,
        COALESCE(hd_buy_potential, 'Not Specified') AS buy_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
), 
HighValueCustomers AS (
    SELECT 
        ci.c_customer_sk,
        ci.gender,
        ci.marital_status,
        ci.purchase_estimate,
        ci.buy_potential
    FROM 
        CustomerInfo ci
    WHERE 
        ci.purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
), 
SalesWithNullLogic AS (
    SELECT 
        r.ws_item_sk,
        SUM(r.ws_net_paid) AS total_sales,
        COALESCE(MAX(CASE WHEN r.ws_net_profit < 0 THEN r.ws_order_number END), 0) AS returns_count,
        AVG(r.ws_net_paid) FILTER (WHERE r.ws_net_paid IS NOT NULL) AS average_payment
    FROM 
        web_sales r
    GROUP BY 
        r.ws_item_sk
)
SELECT 
    hs.ws_item_sk,
    hs.total_sales,
    hs.returns_count,
    COALESCE(r.total_quantity, 0) AS total_quantity_sold,
    rv.order_count,
    CASE 
        WHEN rv.profit_rank = 1 THEN 'Top Seller'
        ELSE 'Regular'
    END AS seller_category,
    jsonb_build_object(
        'HighValueCustomers', 
        (SELECT jsonb_agg(jsonb_build_object('customer_sk', hv.c_customer_sk, 'gender', hv.gender, 'status', hv.marital_status))
        FROM HighValueCustomers hv)
    ) AS high_value_customer_info
FROM 
    SalesWithNullLogic hs
LEFT JOIN 
    RankedSales rv ON hs.ws_item_sk = rv.ws_item_sk
WHERE 
    hs.total_sales IS NOT NULL
ORDER BY 
    hs.total_sales DESC
LIMIT 10;
