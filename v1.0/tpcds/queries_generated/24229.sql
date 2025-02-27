
WITH RECURSIVE DateCycles AS (
    SELECT 
        d_date_sk, 
        d_date, 
        d_year, 
        d_month_seq
    FROM 
        date_dim
    WHERE 
        d_year > 2015
    UNION ALL
    SELECT 
        d.d_date_sk, 
        d.d_date, 
        d.d_year, 
        d.d_month_seq
    FROM 
        date_dim d
    JOIN 
        DateCycles dc ON d.d_date_sk = dc.d_date_sk + 1
    WHERE 
        d.d_year <= 2023
), 
CustomerWithIncome AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT h.hd_income_band_sk) AS income_bands_count,
        MAX(CASE WHEN h.hd_buy_potential IS NULL THEN 0 ELSE 1 END) AS has_potential
    FROM 
        customer c
    LEFT JOIN 
        household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
    GROUP BY 
        c.c_customer_sk
), 
Promotions AS (
    SELECT 
        p.p_promo_sk,
        SUM(p.p_cost) AS total_cost
    FROM 
        promotion p
    GROUP BY 
        p.p_promo_sk
    HAVING 
        SUM(p.p_cost) > 100
), 
WebSalesSummary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM DateCycles)
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    c.c_customer_id,
    cca.ca_city,
    SUM(wss.total_quantity) AS total_web_sales,
    COUNT(DISTINCT p.p_promo_id) AS total_promotions,
    MAX(cb.has_potential) AS highest_income_potential,
    STRING_AGG(DISTINCT CONCAT(COALESCE(cca.ca_street_number, 'N/A'), ' ', cca.ca_street_name, ', ', cca.ca_state, ', ', cca.ca_zip), '; ') AS address_list
FROM 
    customer c
LEFT JOIN 
    customer_address cca ON c.c_current_addr_sk = cca.ca_address_sk
JOIN 
    CustomerWithIncome cb ON c.c_customer_sk = cb.c_customer_sk
LEFT JOIN 
    WebSalesSummary wss ON c.c_customer_sk = wss.ws_item_sk 
LEFT JOIN 
    Promotions p ON wss.ws_item_sk = p.p_promo_sk
WHERE 
    cca.ca_state IS NOT NULL
    AND cb.income_bands_count > 1
    AND (cb.has_potential = 1 OR c.c_email_address IS NULL)
GROUP BY 
    c.c_customer_id, cca.ca_city
ORDER BY 
    total_web_sales DESC, total_promotions DESC
LIMIT 100;
