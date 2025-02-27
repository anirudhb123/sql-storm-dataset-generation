
WITH SalesSummary AS (
    SELECT 
        s.ss_sold_date_sk,
        s.ss_item_sk,
        SUM(s.ss_quantity) AS total_quantity,
        SUM(s.ss_net_paid) AS total_net_sales,
        COUNT(DISTINCT s.ss_ticket_number) AS sales_count
    FROM 
        store_sales s
    WHERE 
        s.ss_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) 
        AND (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        s.ss_sold_date_sk, s.ss_item_sk
),
ItemDetails AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        ROW_NUMBER() OVER (PARTITION BY i.i_category_id ORDER BY i.i_current_price DESC) AS rank
    FROM
        item i
),
CustomerReturns AS (
    SELECT 
        cr.cr_item_sk,
        COUNT(cr.cr_return_quantity) AS total_returns,
        SUM(cr.cr_return_amt) AS total_return_amt
    FROM 
        catalog_returns cr 
    GROUP BY 
        cr.cr_item_sk
)

SELECT 
    ss.ss_sold_date_sk,
    id.i_item_desc,
    id.i_current_price,
    COALESCE(ss.total_quantity, 0) AS total_quantity,
    COALESCE(ss.total_net_sales, 0) AS total_net_sales,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    (COALESCE(ss.total_net_sales, 0) - COALESCE(cr.total_return_amt, 0)) AS net_revenue
FROM 
    SalesSummary ss
FULL OUTER JOIN 
    ItemDetails id ON ss.ss_item_sk = id.i_item_sk
FULL OUTER JOIN 
    CustomerReturns cr ON ss.ss_item_sk = cr.cr_item_sk
WHERE 
    id.rank = 1
ORDER BY 
    net_revenue DESC, total_quantity DESC;
