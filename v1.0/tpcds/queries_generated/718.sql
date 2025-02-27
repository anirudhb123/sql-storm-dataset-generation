
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_web_site_sk
),
CustomerReturns AS (
    SELECT 
        cr.cr_returned_date_sk,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_return_amt) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM 
        catalog_returns cr
    JOIN 
        date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        cr.cr_returned_date_sk
),
TotalPerformance AS (
    SELECT 
        d.d_year,
        COALESCE(s.total_sales_quantity, 0) AS total_sales_quantity,
        COALESCE(s.total_net_profit, 0) AS total_net_profit,
        COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(r.total_return_amount, 0) AS total_return_amount
    FROM 
        date_dim d
    LEFT JOIN 
        SalesData s ON d.d_date_sk = s.ws_sold_date_sk
    LEFT JOIN 
        CustomerReturns r ON d.d_date_sk = r.cr_returned_date_sk
    WHERE 
        d.d_year = 2023
),
RankedPerformance AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_net_profit DESC) AS overall_rank
    FROM 
        TotalPerformance
)
SELECT 
    tp.d_year,
    tp.total_sales_quantity,
    tp.total_net_profit,
    tp.total_return_quantity,
    tp.total_return_amount,
    rp.overall_rank
FROM 
    TotalPerformance tp
JOIN 
    RankedPerformance rp ON tp.d_year = rp.d_year
WHERE 
    tp.total_net_profit > 0.00
ORDER BY 
    rp.overall_rank;
