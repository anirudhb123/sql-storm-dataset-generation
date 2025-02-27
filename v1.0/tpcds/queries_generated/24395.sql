
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_return_quantity,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS return_rank,
        SUM(sr_return_quantity) OVER (PARTITION BY sr_item_sk) AS total_returns
    FROM 
        store_returns
),
RecentReturns AS (
    SELECT 
        rr.sr_item_sk,
        rr.return_quantity,
        rr.total_returns,
        DATEDIFF(CURRENT_DATE, DATE(ADD_MONTHS(CURRENT_DATE, -3))) AS days_since_return
    FROM 
        RankedReturns rr
    WHERE 
        rr.return_rank = 1
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        COUNT(r.sr_item_sk) AS return_count
    FROM 
        customer c
    LEFT JOIN 
        store_returns r ON c.c_customer_sk = r.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        COUNT(r.sr_item_sk) > 2
),
ItemSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_sales_price) AS total_revenue
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CombinedData AS (
    SELECT 
        ir.sr_item_sk,
        ir.return_quantity,
        ir.total_returns,
        it.total_sold,
        it.total_revenue
    FROM 
        RecentReturns ir
    JOIN 
        ItemSales it ON ir.sr_item_sk = it.ws_item_sk
),
FinalOutput AS (
    SELECT 
        cd.sr_item_sk,
        cd.return_quantity,
        cd.total_returns,
        cd.total_sold,
        cd.total_revenue,
        COALESCE((cd.total_sold / NULLIF(cd.total_returns, 0)), 0) AS sale_to_return_ratio
    FROM 
        CombinedData cd
),
FinalRanking AS (
    SELECT 
        fo.sr_item_sk,
        fo.return_quantity,
        fo.total_returns,
        fo.total_sold,
        fo.total_revenue,
        fo.sale_to_return_ratio,
        DENSE_RANK() OVER (ORDER BY fo.sale_to_return_ratio DESC) AS rank
    FROM 
        FinalOutput fo
)
SELECT 
    fr.sr_item_sk,
    fr.return_quantity,
    fr.total_returns,
    fr.total_sold,
    fr.total_revenue,
    fr.sale_to_return_ratio,
    CASE 
        WHEN fr.rank = 1 THEN 'Top Performer'
        WHEN fr.rank <= 10 THEN 'Top 10'
        ELSE 'Below Average'
    END AS performance_category
FROM 
    FinalRanking fr
LEFT JOIN 
    TopCustomers tc ON fr.sr_item_sk = tc.c_customer_sk
WHERE 
    fr.sale_to_return_ratio > 1 OR fr.total_returns > 5
ORDER BY 
    fr.sale_to_return_ratio DESC, fr.return_quantity DESC;

