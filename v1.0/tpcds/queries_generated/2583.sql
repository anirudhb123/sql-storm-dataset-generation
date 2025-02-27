
WITH RankedSales AS (
    SELECT 
        ws_sales_date_sk,
        ws_item_sk,
        ws_sold_date_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) as sales_rank,
        SUM(ws_quantity) OVER (PARTITION BY ws_item_sk) as total_quantity
    FROM web_sales
),
CustomerReturnStats AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM store_returns
    GROUP BY sr_customer_sk
),
WebSalesWithReturns AS (
    SELECT 
        w.ws_item_sk,
        w.ws_sales_price,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(r.total_returned_amount, 0) AS total_returned_amount,
        (w.ws_sales_price * w.ws_quantity) - COALESCE(r.total_returned_amount, 0) AS net_sales
    FROM RankedSales w
    LEFT JOIN CustomerReturnStats r ON w.ws_customer_sk = r.sr_customer_sk
    WHERE w.sales_rank = 1
),
IncomeStats AS (
    SELECT 
        h.hd_income_band_sk,
        AVG(sr_net_loss) AS avg_net_loss,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer c
    LEFT JOIN household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY h.hd_income_band_sk
)
SELECT 
    wb.ws_item_sk,
    wb.ws_sales_price,
    wb.total_returns,
    wb.total_returned_quantity,
    wb.net_sales,
    isd.hd_income_band_sk,
    isd.avg_net_loss,
    isd.customer_count
FROM WebSalesWithReturns wb
JOIN IncomeStats isd ON wb.ws_item_sk IN (
    SELECT i_item_sk FROM item WHERE i_current_price > 25.00
)
ORDER BY wb.net_sales DESC, isd.customer_count ASC;
