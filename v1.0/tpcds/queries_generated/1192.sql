
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0
    GROUP BY 
        ws.web_site_id, ws_item_sk
), 
TopStores AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS total_net_profit
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    GROUP BY 
        ss_store_sk
), 
CustomerReturns AS (
    SELECT 
        CASE 
            WHEN sr_returned_date_sk IS NOT NULL THEN 'Store'
            WHEN wr_returned_date_sk IS NOT NULL THEN 'Web'
            ELSE 'Unknown'
        END AS return_type,
        COUNT(*) AS total_returns,
        SUM(COALESCE(sr_net_loss, 0) + COALESCE(wr_net_loss, 0)) AS total_loss
    FROM 
        store_returns sr
    FULL OUTER JOIN 
        web_returns wr ON sr.wr_item_sk = wr.wr_item_sk AND sr.sr_return_number = wr.wr_order_number
    GROUP BY 
        return_type
)
SELECT 
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    ca.ca_city,
    ca.ca_state,
    ts.total_net_profit,
    cr.total_returns,
    cr.total_loss
FROM 
    customer cs
LEFT JOIN 
    customer_address ca ON cs.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    TopStores ts ON cs.c_customer_sk = ts.ss_store_sk
LEFT JOIN 
    CustomerReturns cr ON cr.return_type = 
        (CASE 
            WHEN ts.total_net_profit > 100000 THEN 'Store'
            ELSE 'Web'
        END)
WHERE 
    cs.c_birth_year < 1980 
    AND (cr.total_returns > 0 OR cr.total_loss > 0)
ORDER BY 
    ts.total_net_profit DESC, 
    cr.total_loss ASC
LIMIT 100;
