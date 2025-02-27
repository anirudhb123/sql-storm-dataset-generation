
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws_sold_date_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 1000
    GROUP BY 
        ws.web_site_id, ws_sold_date_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
        AND cd.cd_gender IS NOT NULL
),
SalesWithReturns AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COALESCE(SUM(sr_return_amt), 0) AS total_returned_amount,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(sr_ticket_number) AS total_returns
    FROM 
        web_sales ws
    LEFT JOIN 
        store_returns sr ON ws.ws_order_number = sr.sr_ticket_number
    GROUP BY 
        ws.ws_order_number
    HAVING 
        SUM(ws.ws_net_paid) - COALESCE(SUM(sr_return_amt), 0) > 0
),
FinalReport AS (
    SELECT 
        r.web_site_id,
        r.total_orders,
        r.total_sales,
        r.sales_rank,
        h.c_customer_id,
        h.cd_gender,
        h.cd_marital_status,
        h.cd_purchase_estimate,
        h.cd_credit_rating,
        sr.total_net_paid,
        sr.total_returned_amount,
        sr.total_profit,
        sr.total_returns
    FROM 
        RankedSales r
    JOIN 
        HighValueCustomers h ON h.cd_credit_rating = 'Good'
    LEFT JOIN 
        SalesWithReturns sr ON sr.ws_order_number IN (
            SELECT ws_order_number FROM web_sales
            WHERE ws_bill_customer_sk = (
                SELECT c_customer_sk FROM customer
                WHERE c_customer_id = h.c_customer_id
            )
        )
)
SELECT 
    web_site_id,
    total_orders,
    total_sales,
    sales_rank,
    c_customer_id,
    cd_gender,
    cd_marital_status,
    cd_purchase_estimate,
    cd_credit_rating,
    COALESCE(total_net_paid, 0) AS net_paid,
    COALESCE(total_returned_amount, 0) AS returned_amount,
    total_profit,
    total_returns,
    CONCAT('Website: ', web_site_id, ' | Customer: ', c_customer_id) AS summary
FROM 
    FinalReport
WHERE 
    total_sales > 10000
ORDER BY 
    total_sales DESC, total_orders ASC
LIMIT 50;
