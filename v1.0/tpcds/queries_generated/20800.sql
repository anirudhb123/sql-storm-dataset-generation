
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
FilteredSales AS (
    SELECT 
        rs.ws_sold_date_sk,
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_revenue,
        CASE 
            WHEN rs.total_quantity > 100 THEN 'High Volume'
            ELSE 'Low Volume'
        END AS sales_category,
        COALESCE(ca_street_name || ', ' || ca_city || ', ' || ca_state, 'Unknown Location') AS full_address
    FROM 
        RankedSales rs
    LEFT JOIN 
        customer c ON c.c_customer_sk = (SELECT cc_call_center_sk FROM call_center WHERE cc_open_date_sk = rs.ws_sold_date_sk LIMIT 1)
    LEFT JOIN 
        customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
    WHERE 
        rs.rank <= 3
),
ReturnMetrics AS (
    SELECT 
        wr_returned_date_sk,
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS return_revenue
    FROM 
        web_returns
    GROUP BY 
        wr_returned_date_sk, wr_item_sk
),
FinalReport AS (
    SELECT 
        fs.ws_sold_date_sk,
        fs.ws_item_sk,
        fs.total_quantity,
        fs.total_revenue,
        fs.sales_category,
        fs.full_address,
        COALESCE(rm.total_returns, 0) AS total_returns,
        COALESCE(rm.return_revenue, 0) AS return_revenue,
        CASE 
            WHEN fs.total_revenue > COALESCE(rm.return_revenue, 0) THEN 'Profitable'
            ELSE 'Unprofitable'
        END AS profitability_status
    FROM 
        FilteredSales fs
    LEFT JOIN 
        ReturnMetrics rm ON fs.ws_sold_date_sk = rm.wr_returned_date_sk AND fs.ws_item_sk = rm.wr_item_sk
)
SELECT 
    fp.ws_sold_date_sk,
    fp.ws_item_sk,
    fp.total_quantity,
    fp.total_revenue,
    fp.sales_category,
    fp.full_address,
    fp.total_returns,
    fp.return_revenue,
    fp.profitability_status
FROM 
    FinalReport fp
WHERE 
    (fp.sales_category = 'High Volume' AND fp.total_returns = 0) OR 
    (fp.sales_category = 'Low Volume' AND fp.profitability_status = 'Unprofitable')
ORDER BY 
    fp.ws_sold_date_sk ASC, 
    fp.total_revenue DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
