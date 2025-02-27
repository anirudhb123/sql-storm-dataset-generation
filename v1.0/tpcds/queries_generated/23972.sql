
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) as price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
MonthlyReturns AS (
    SELECT 
        EXTRACT(YEAR FROM dd.d_date) AS return_year,
        EXTRACT(MONTH FROM dd.d_date) AS return_month,
        COUNT(DISTINCT cr.cr_order_number) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    JOIN 
        date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
    WHERE 
        cr.cr_return_amount > 0
    GROUP BY 
        return_year, return_month
),
TopItems AS (
    SELECT 
        item.i_item_sk,
        item.i_item_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue
    FROM 
        item item
    JOIN 
        web_sales ws ON ws.ws_item_sk = item.i_item_sk
    GROUP BY 
        item.i_item_sk, item.i_item_id
    HAVING 
        SUM(ws.ws_net_paid_inc_tax) > (
            SELECT 
                AVG(total_revenue)
            FROM (
                SELECT 
                    SUM(ws.ws_net_paid_inc_tax) AS total_revenue
                FROM 
                    web_sales ws
                GROUP BY 
                    ws.ws_item_sk
            ) AS avg_sales
        )
),
BestCustomers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
    HAVING 
        SUM(ws.ws_net_paid) > 1000
)
SELECT 
    ci.c_item_id,
    COUNT(DISTINCT rc.c_customer_id) AS repeat_customers,
    AVG(COALESCE(sg.total_return_amount, 0)) AS average_return_value,
    SUM(ri.total_revenue) AS total_item_revenue
FROM 
    (SELECT 
        item.i_item_id, 
        item.i_item_sk 
     FROM 
        item 
     JOIN 
        RankedSales rs ON item.i_item_sk = rs.ws_item_sk
     WHERE 
        rs.price_rank = 1
    ) ci
LEFT JOIN 
    BestCustomers rc ON rc.total_spent >= 500
LEFT JOIN 
    MonthlyReturns sg ON sg.return_month = EXTRACT(MONTH FROM CURRENT_DATE)
LEFT JOIN 
    TopItems ri ON ri.i_item_sk = ci.i_item_sk
GROUP BY 
    ci.c_item_id
HAVING 
    COUNT(DISTINCT rc.c_customer_id) > 5
ORDER BY 
    total_item_revenue DESC;
