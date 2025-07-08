
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) as profit_rank,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
        AND ws.ws_sales_price > 0
        AND cd.cd_marital_status IS NOT NULL
), AggregateReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
), JoinResults AS (
    SELECT 
        rs.ws_item_sk,
        AVG(rs.ws_sales_price) AS avg_sales_price,
        ar.total_returns,
        ar.total_return_amt,
        COUNT(DISTINCT rs.ws_order_number) AS order_count
    FROM 
        RankedSales rs
    LEFT JOIN 
        AggregateReturns ar ON rs.ws_item_sk = ar.sr_item_sk
    GROUP BY 
        rs.ws_item_sk, ar.total_returns, ar.total_return_amt
)

SELECT 
    j.ws_item_sk,
    j.avg_sales_price,
    j.total_returns,
    COALESCE(j.total_return_amt, 0) AS safe_return_amt,
    CASE 
        WHEN j.order_count IS NULL THEN 'No Sales' 
        ELSE 'Sales Exist' 
    END AS sales_status
FROM 
    JoinResults j
WHERE 
    j.total_returns > (SELECT AVG(total_returns) FROM AggregateReturns WHERE total_returns IS NOT NULL) 
    OR j.avg_sales_price > 100
ORDER BY 
    j.avg_sales_price DESC, j.total_returns DESC
LIMIT 10 OFFSET (SELECT COUNT(*) / 2 FROM JoinResults);
