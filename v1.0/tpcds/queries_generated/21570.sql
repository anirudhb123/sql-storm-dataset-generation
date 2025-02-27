
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_store_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        sr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM 
        store_returns 
    WHERE 
        sr_return_quantity > 0
),
SalesData AS (
    SELECT 
        ws_ship_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_paid_inc_tax) AS total_revenue,
        AVG(ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk, ws_item_sk
),
FilteredSales AS (
    SELECT 
        sd.ws_ship_date_sk,
        sd.ws_item_sk,
        sd.total_sold,
        sd.total_revenue,
        sd.avg_order_value,
        ca.ca_city,
        ca.ca_state
    FROM 
        SalesData sd
    JOIN 
        customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = (SELECT DISTINCT sr_returning_customer_sk FROM CustomerReturns cr WHERE cr.sr_item_sk = sd.ws_item_sk LIMIT 1))
    WHERE 
        ca.ca_state IS NOT NULL
),
WeeklySales AS (
    SELECT 
        d.d_week_seq,
        s.ws_item_sk,
        SUM(s.total_sold) AS weekly_quantity_sold,
        SUM(s.total_revenue) AS weekly_revenue,
        COUNT(DISTINCT s.ws_ship_date_sk) AS unique_days_sold
    FROM 
        FilteredSales s 
    JOIN 
        date_dim d ON d.d_date_sk = s.ws_ship_date_sk
    GROUP BY 
        d.d_week_seq, s.ws_item_sk
)
SELECT 
    ws.ws_item_sk,
    ws.weekly_quantity_sold,
    ws.weekly_revenue,
    ws.unique_days_sold,
    DENSE_RANK() OVER (ORDER BY ws.weekly_revenue DESC) AS revenue_rank,
    COALESCE(MAX(r.r_reason_desc), 'No Reason') AS reason_description,
    CASE 
        WHEN ws.weekly_quantity_sold > 100 THEN 'High Volume'
        WHEN ws.weekly_quantity_sold IS NULL THEN 'No Sales'
        ELSE 'Normal Volume' 
    END AS sales_category
FROM 
    WeeklySales ws
LEFT JOIN 
    reason r ON r.r_reason_sk = (SELECT TOP 1 sr_reason_sk FROM store_returns sr WHERE sr_return_quantity < 0 AND sr_item_sk = ws.ws_item_sk ORDER BY sr_returned_date_sk DESC)
GROUP BY 
    ws.ws_item_sk, ws.weekly_quantity_sold, ws.weekly_revenue, ws.unique_days_sold
HAVING 
    ws.weekly_revenue > (SELECT AVG(total_revenue) FROM WeeklySales) 
UNION ALL 
SELECT 
    0 AS ws_item_sk, 
    COUNT(*) AS weekly_quantity_sold, 
    SUM(ws_ext_sales_price) AS weekly_revenue,
    COUNT(DISTINCT ss_ticket_number) AS unique_days_sold,
    1 AS revenue_rank,
    'Aggregated Total' AS reason_description,
    'Total Sales' AS sales_category
FROM 
    store_sales
WHERE 
    ss_sold_date_sk IN (SELECT DISTINCT sr_returned_date_sk FROM store_returns)
ORDER BY 
    revenue_rank;
