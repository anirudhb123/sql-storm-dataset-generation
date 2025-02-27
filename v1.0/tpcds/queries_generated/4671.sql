
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws.web_site_id
), 
TopWebsites AS (
    SELECT 
        web_site_id
    FROM RankedSales
    WHERE sales_rank <= 5
),
CustomerReturns AS (
    SELECT 
        wr_refunded_customer_sk,
        SUM(wr_return_amt) AS total_refunded
    FROM web_returns
    WHERE wr_returned_date_sk IN (
        SELECT cr_returned_date_sk
        FROM catalog_returns
        WHERE cr_item_sk IN (
            SELECT DISTINCT ws_item_sk 
            FROM web_sales 
            WHERE ws.web_site_sk IN (SELECT web_site_sk FROM web_site WHERE web_class = 'Premium')
        )
    )
    GROUP BY wr_refunded_customer_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(ws.ws_net_profit) AS total_profit,
    COALESCE(SUM(cr_total_refund.total_refunded), 0) AS total_refunds
FROM web_sales ws
LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN (
    SELECT 
        wr_refunded_customer_sk,
        SUM(wr_return_amt) AS total_refunded
    FROM web_returns
    WHERE wr_returned_date_sk IN (
        SELECT cr_returned_date_sk 
        FROM catalog_returns
    )
    GROUP BY wr_refunded_customer_sk
) cr_total_refund ON cr_total_refund.wr_refunded_customer_sk = c.c_customer_sk
WHERE ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
    AND c.c_customer_sk IN (SELECT DISTINCT sr_customer_sk FROM store_returns)
GROUP BY ca.ca_city, ca.ca_state
ORDER BY total_profit DESC, total_refunds DESC;
