
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_sk
),
CustomerPromoDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        LOWER(c.c_first_name) LIKE '%a%' AND 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, p.p_promo_name
),
ReturnStats AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    GROUP BY 
        sr_item_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COALESCE(CASE 
        WHEN inv.inv_quantity_on_hand IS NULL THEN 'Out of Stock'
        ELSE 'In Stock' 
    END, 'Not Found') AS stock_status,
    SUM(cs.cs_sales_price) AS total_sales,
    AVG(rd.total_net_profit) AS avg_net_profit,
    COUNT(DISTINCT cpd.c_customer_sk) AS customer_count 
FROM 
    customer_address ca
LEFT JOIN 
    inventory inv ON ca.ca_address_sk = inv.inv_warehouse_sk
LEFT JOIN 
    store_sales cs ON cs.ss_item_sk = inv.inv_item_sk
LEFT JOIN 
    RankedSales rd ON rd.web_site_sk = inv.inv_warehouse_sk
LEFT JOIN 
    CustomerPromoDetails cpd ON cpd.c_customer_sk = ca.ca_address_sk
LEFT JOIN 
    ReturnStats rs ON rs.sr_item_sk = inv.inv_item_sk
WHERE 
    ca.ca_state IS NOT NULL 
    AND (ca.ca_zip <> '00000' OR ca.ca_zip IS NULL)
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    AVG(rd.total_net_profit) > (
        SELECT 
            AVG(total_net_profit) 
        FROM 
            RankedSales 
        WHERE 
            profit_rank <= 10
    )
ORDER BY 
    total_sales DESC, customer_count ASC;
