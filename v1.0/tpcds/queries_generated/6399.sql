
WITH RankedReturns AS (
    SELECT 
        sr.returned_date_sk,
        sr.return_time_sk,
        sr.item_sk,
        sr.return_quantity,
        sr.return_amt,
        sr.return_tax,
        sr.return_amt_inc_tax,
        sr.return_ship_cost,
        sr.returned_customer_sk,
        RANK() OVER (PARTITION BY sr.item_sk ORDER BY sr.return_quantity DESC) AS rank
    FROM 
        store_returns sr
    JOIN 
        date_dim dd ON sr.returned_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
), TotalReturns AS (
    SELECT 
        rr.item_sk,
        SUM(rr.return_quantity) AS total_returned_quantity,
        SUM(rr.return_amt_inc_tax) AS total_returned_amt,
        COUNT(*) AS return_count
    FROM 
        RankedReturns rr
    WHERE 
        rr.rank <= 10
    GROUP BY 
        rr.item_sk
), ItemDetails AS (
    SELECT 
        i.item_sk,
        i.item_desc,
        i.current_price,
        i.list_price,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        item i
    LEFT JOIN 
        income_band ib ON i.item_sk % 10 = ib.ib_income_band_sk -- Just for example
), ReturnSummary AS (
    SELECT 
        id.item_sk,
        id.item_desc,
        id.current_price,
        id.list_price,
        tr.total_returned_quantity,
        tr.total_returned_amt,
        tr.return_count,
        CASE 
            WHEN tr.total_returned_quantity > 100 THEN 'High Return' 
            ELSE 'Normal Return' 
        END AS return_category
    FROM 
        ItemDetails id
    LEFT JOIN 
        TotalReturns tr ON id.item_sk = tr.item_sk
)
SELECT 
    rs.item_sk,
    rs.item_desc,
    rs.current_price,
    rs.list_price,
    rs.total_returned_quantity,
    rs.total_returned_amt,
    rs.return_count,
    rs.return_category
FROM 
    ReturnSummary rs
ORDER BY 
    rs.total_returned_quantity DESC
LIMIT 50;
