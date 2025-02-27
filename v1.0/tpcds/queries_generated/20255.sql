
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        ROW_NUMBER() OVER(PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn,
        COALESCE(SUM(sr_return_quantity) OVER(PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk 
                                              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS cumulative_return_quantity
    FROM store_returns
),

CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS average_profit,
        CD.cd_gender,
        D.d_month_seq
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN customer_demographics CD ON c.c_current_cdemo_sk = CD.cd_demo_sk
    JOIN date_dim D ON ws.ws_sold_date_sk = D.d_date_sk
    WHERE D.d_year = 2022
    GROUP BY c.c_customer_id, CD.cd_gender, D.d_month_seq
),

SalesSummary AS (
    SELECT 
        cs.cs_item_sk,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(cs.cs_ext_sales_price) AS total_revenue,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        AVG(cs.cs_net_profit) AS average_net_profit
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk
),

FinalReport AS (
    SELECT 
        r.rn,
        r.sr_item_sk,
        cs.total_sales,
        cs.average_profit,
        ss.total_orders,
        ss.total_revenue,
        ss.total_discount,
        ss.average_net_profit,
        COALESCE(NULLIF(r.cumulative_return_quantity, 0), NULL) AS adjusted_return_quantity
    FROM RankedReturns r
    LEFT JOIN CustomerSales cs ON r.sr_customer_sk = cs.c_customer_id
    LEFT JOIN SalesSummary ss ON r.sr_item_sk = ss.cs_item_sk
    WHERE r.rn = 1 AND (ss.total_revenue IS NOT NULL OR cs.total_sales IS NOT NULL)
)

SELECT 
    f.rn,
    f.sr_item_sk,
    f.total_sales,
    f.average_profit,
    f.total_orders,
    f.total_revenue,
    f.total_discount,
    f.average_net_profit,
    CASE 
        WHEN f.adjusted_return_quantity IS NOT NULL THEN 'Has Returns' 
        ELSE 'No Returns' 
    END AS return_status
FROM FinalReport f
WHERE f.adjusted_return_quantity IS NULL OR f.adjusted_return_quantity > 0
ORDER BY f.total_orders DESC, f.total_revenue DESC;
