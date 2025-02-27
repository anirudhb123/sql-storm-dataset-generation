
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_paid,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) as sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_paid > 0
),
TopSales AS (
    SELECT 
        rs.web_site_sk,
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        rs.ws_net_paid
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 10
),
CustomerReturns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
WebReturns AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_quantity) AS total_web_returns,
        SUM(wr_return_amt) AS total_web_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
)
SELECT 
    cs.ws_order_number,
    cs.ws_item_sk,
    COALESCE(cr.total_returns, 0) AS total_store_returns,
    COALESCE(wr.total_web_returns, 0) AS total_web_returns,
    cs.ws_sales_price,
    cs.ws_net_paid,
    (CASE 
        WHEN COALESCE(cr.total_returns, 0) > 0 THEN 'Returned'
        ELSE 'Active'
     END) AS sale_status
FROM 
    TopSales cs
LEFT JOIN 
    CustomerReturns cr ON cs.ws_item_sk = cr.sr_item_sk
LEFT JOIN 
    WebReturns wr ON cs.ws_item_sk = wr.wr_item_sk
WHERE 
    (cs.ws_sales_price > (SELECT AVG(ws_sales_price) FROM web_sales WHERE ws_item_sk IS NOT NULL)
      OR (
          SELECT COUNT(*) FROM web_sales WHERE ws_item_sk = cs.ws_item_sk
      ) > 5)
ORDER BY 
    cs.ws_net_paid DESC, sale_status ASC;
