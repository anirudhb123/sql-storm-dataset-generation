
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk, 
        COUNT(DISTINCT sr_ticket_number) as num_returns, 
        SUM(sr_return_amt) as total_return_amt,
        SUM(sr_return_tax) as total_return_tax,
        SUM(sr_return_amt_inc_tax) as total_return_amt_inc_tax,
        SUM(sr_return_ship_cost) as total_return_ship_cost
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        sr_returned_date_sk
),
ItemSales AS (
    SELECT 
        ws_sold_date_sk, 
        SUM(ws_quantity) as total_quantity_sold, 
        SUM(ws_sales_price) as total_sales_amt, 
        SUM(ws_net_profit) as total_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk
),
CombinedData AS (
    SELECT 
        d.d_date_id,
        COALESCE(cr.num_returns, 0) as num_returns,
        COALESCE(cr.total_return_amt, 0) as total_return_amt,
        COALESCE(cr.total_return_tax, 0) as total_return_tax,
        COALESCE(cr.total_return_amt_inc_tax, 0) as total_return_amt_inc_tax,
        COALESCE(cr.total_return_ship_cost, 0) as total_return_ship_cost,
        COALESCE(is.total_quantity_sold, 0) as total_quantity_sold,
        COALESCE(is.total_sales_amt, 0) as total_sales_amt,
        COALESCE(is.total_net_profit, 0) as total_net_profit
    FROM 
        date_dim d
    LEFT JOIN 
        CustomerReturns cr ON d.d_date_sk = cr.returned_date_sk
    LEFT JOIN 
        ItemSales is ON d.d_date_sk = is.ws_sold_date_sk
    WHERE 
        d.d_year = 2023
)
SELECT 
    d.d_date_id,
    d.num_returns,
    d.total_return_amt,
    d.total_return_tax,
    d.total_return_amt_inc_tax,
    d.total_return_ship_cost,
    d.total_quantity_sold,
    d.total_sales_amt,
    d.total_net_profit
FROM 
    CombinedData d
ORDER BY 
    d.d_date_id;
