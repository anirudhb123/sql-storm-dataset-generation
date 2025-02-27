
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.item_sk,
        ws.sales_price,
        ws.net_paid,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY ws.net_paid DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
),
HighValueItems AS (
    SELECT 
        i.item_id,
        i.item_desc,
        COUNT(DISTINCT wr.returning_customer_sk) AS return_count,
        SUM(wr.return_amt) AS total_return_amt
    FROM 
        item i
    JOIN 
        web_returns wr ON i.item_sk = wr.item_sk
    WHERE 
        wr.returned_date_sk BETWEEN (SELECT MIN(ws.sold_date_sk) FROM web_sales ws WHERE ws.net_paid > 100) AND 
                                    (SELECT MAX(ws.sold_date_sk) FROM web_sales ws WHERE ws.net_paid > 100)
    GROUP BY 
        i.item_id, i.item_desc
    HAVING 
        SUM(wr.return_amt) > (SELECT AVG(total_sales) FROM (
            SELECT 
                SUM(ws.net_paid) AS total_sales
            FROM 
                web_sales ws
            GROUP BY 
                ws.item_sk
        ) AS avg_sales)
),
FinalResults AS (
    SELECT 
        ca.city,
        SUM(s.net_profit) AS total_net_profit,
        AVG(cd.purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT i.brand) AS brands_offered,
        COUNT(DISTINCT sr.reversed_charge) AS reverse_count,
        COUNT(DISTINCT cs.order_number) FILTER (WHERE cs.ext_discount_amt > 0) AS discounted_orders
    FROM 
        customer_address ca
    LEFT JOIN 
        store_sales s ON ca.ca_address_sk = s.store_sk
    LEFT JOIN 
        customer c ON c.c_customer_sk = s.customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        HighValueItems hvi ON hvi.item_id = s.item_sk
    LEFT JOIN 
        catalog_sales cs ON cs.item_sk = s.item_sk
    LEFT JOIN 
        store_returns sr ON sr.store_sk = s.store_sk AND s.ticket_number = sr.ticket_number
    WHERE 
        ca.city IS NOT NULL AND
        ca.city != 'unknown' AND
        cd.cd_marital_status IS NOT NULL
    GROUP BY 
        ca.city
    HAVING 
        SUM(s.net_profit) > 50000 AND 
        COUNT(DISTINCT c.customer_id) > 10
)
SELECT 
    fr.city,
    fr.total_net_profit,
    fr.avg_purchase_estimate,
    fr.brands_offered,
    COALESCE(fr.reverse_count, 0) AS total_reversals,
    COALESCE(fr.discounted_orders, 0) AS total_discounted_orders,
    (SELECT COUNT(*) FROM RankedSales WHERE sales_rank = 1) AS highest_sales_count
FROM 
    FinalResults fr
ORDER BY 
    fr.total_net_profit DESC
LIMIT 10;
