
WITH RankedSales AS (
    SELECT 
        s_store_sk,
        COUNT(ss_ticket_number) AS total_sales,
        SUM(ss_net_paid_inc_tax) AS total_revenue,
        RANK() OVER (PARTITION BY s_store_sk ORDER BY SUM(ss_net_profit) DESC) AS sales_rank,
        (SELECT AVG(ss_net_profit) 
         FROM store_sales 
         WHERE ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)) AS avg_profit_2023
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ss_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        s_store_sk
),
StoreInfo AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_city,
        s_state,
        AVG(s_number_employees) AS avg_employees,
        SUM(CASE WHEN s_closed_date_sk IS NULL THEN 1 ELSE 0 END) AS open_stores
    FROM 
        store
    GROUP BY 
        s_store_sk, s_store_name, s_city, s_state
),
ReturnData AS (
    SELECT 
        sr_store_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_value
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IN (
            SELECT d_date_sk FROM date_dim WHERE d_year = 2023
        )
    GROUP BY 
        sr_store_sk
)
SELECT 
    si.s_store_name,
    si.s_city,
    si.s_state,
    rs.total_sales,
    rs.total_revenue,
    rs.sales_rank,
    rd.total_returns,
    rd.total_returned_value,
    si.avg_employees,
    si.open_stores,
    COALESCE((rs.total_revenue - rd.total_returned_value) / NULLIF(rs.total_revenue, 0), 0) AS net_revenue_ratio,
    CASE 
        WHEN rs.total_sales = 0 THEN 'No Sales'
        WHEN rs.total_sales > 100 THEN 'High Sales'
        ELSE 'Moderate Sales'
    END AS sales_category
FROM 
    StoreInfo si
LEFT JOIN 
    RankedSales rs ON si.s_store_sk = rs.s_store_sk
LEFT JOIN 
    ReturnData rd ON si.s_store_sk = rd.sr_store_sk
WHERE 
    si.avg_employees > (SELECT AVG(avg_employees) FROM StoreInfo)
    OR COALESCE(rs.total_revenue, 0) > (SELECT AVG(total_revenue) FROM RankedSales)
ORDER BY 
    net_revenue_ratio DESC,
    sales_rank ASC
LIMIT 100;
