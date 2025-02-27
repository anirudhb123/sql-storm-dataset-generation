
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
),
TotalReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        SUM(cr_net_loss) AS total_net_loss
    FROM catalog_returns
    GROUP BY cr_item_sk
),
CustomerPreferences AS (
    SELECT 
        c.c_customer_sk,
        d.cd_gender,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales_value
    FROM customer c
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, d.cd_gender
),
ItemStatistics AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(ts.total_returned_quantity, 0) AS returns_count,
        COALESCE(ts.total_net_loss, 0) AS total_net_loss,
        AVG(rs.ws_sales_price) AS avg_sales_price,
        SUM(rs.ws_quantity) AS total_quantity_sold
    FROM item i
    LEFT JOIN TotalReturns ts ON i.i_item_sk = ts.cr_item_sk
    LEFT JOIN RankedSales rs ON i.i_item_sk = rs.ws_item_sk AND rs.rn = 1
    GROUP BY i.i_item_sk, i.i_item_desc
)
SELECT 
    it.i_item_sk, 
    it.i_item_desc, 
    it.total_quantity_sold, 
    it.avg_sales_price, 
    it.returns_count,
    it.total_net_loss,
    cp.c_customer_sk,
    cp.cd_gender,
    cp.total_quantity_sold AS customer_total_quantity
FROM ItemStatistics it
JOIN CustomerPreferences cp ON it.total_quantity_sold > cp.total_quantity_sold
WHERE it.returns_count > 0
ORDER BY it.total_net_loss DESC, cp.cd_gender;
