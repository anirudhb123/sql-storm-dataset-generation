
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS ReturnRank
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
), 
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        COALESCE(hd.hd_buy_potential, 'UNKNOWN') AS buy_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    WHERE 
        (cd.cd_gender = 'M' AND cd.cd_marital_status = 'S')
        OR (cd.cd_gender = 'F' AND cd.cd_marital_status IS NULL)
), 
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
    HAVING 
        SUM(ws.ws_quantity) > 100
), 
ReturnStatistics AS (
    SELECT 
        r.ret_item_sk,
        AVG(r.ret_quantity) AS avg_return_quantity,
        COUNT(*) AS total_returns,
        SUM(r.ret_quantity) AS overall_return_amount
    FROM 
        (SELECT 
            sr_item_sk AS ret_item_sk,
            sr_return_quantity AS ret_quantity
        FROM 
            store_returns 
        WHERE 
            sr_return_quantity IS NOT NULL) r
    GROUP BY 
        r.ret_item_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ci.ca_state,
    ss.total_quantity,
    ss.total_revenue,
    rs.avg_return_quantity,
    rs.total_returns,
    CASE 
        WHEN rs.total_returns IS NULL OR rs.total_returns = 0 THEN 'No Returns'
        ELSE 'Returned ' || CAST(rs.total_returns AS VARCHAR)
    END AS return_message,
    CASE 
        WHEN rs.avg_return_quantity > 5 THEN 'High Returns'
        WHEN rs.avg_return_quantity BETWEEN 1 AND 5 THEN 'Moderate Returns'
        ELSE 'Low Returns'
    END AS return_level
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesData ss ON ci.c_customer_sk = ss.ws_item_sk
LEFT JOIN 
    ReturnStatistics rs ON ss.ws_item_sk = rs.ret_item_sk
WHERE 
    ci.buy_potential <> 'UNKNOWN'
ORDER BY 
    ci.ca_city ASC, ci.c_last_name DESC
OFFSET 10 LIMIT 5;
