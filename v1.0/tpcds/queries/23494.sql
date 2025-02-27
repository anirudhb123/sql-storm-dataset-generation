
WITH RankedPromotions AS (
    SELECT 
        p.p_promo_id, 
        p.p_discount_active, 
        DENSE_RANK() OVER (PARTITION BY p.p_item_sk ORDER BY p.p_response_target DESC) AS promo_rank
    FROM 
        promotion p
    WHERE 
        p.p_discount_active = 'Y'
),
CustomerStats AS (
    SELECT 
        ca.ca_city, 
        cd.cd_gender, 
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
        AVG(cd.cd_purchase_estimate) AS average_purchase_estimate
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_city, cd.cd_gender
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_sales_price,
        ws.ws_ext_discount_amt,
        COALESCE(ws.ws_net_paid_inc_tax, 0) AS net_paid_tax_adjusted
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_mode_sk IS NOT NULL
      AND 
        ws.ws_net_profit > 0
),
ReturnsData AS (
    SELECT 
        sr.sr_customer_sk, 
        SUM(COALESCE(sr.sr_return_amt_inc_tax, 0)) AS total_returned,
        SUM(COALESCE(sr.sr_return_quantity, 0)) AS total_returned_quantity
    FROM 
        store_returns sr 
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    cs.ca_city,
    cs.cd_gender,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN cs.married_count > 0 THEN 1 ELSE 0 END) AS total_married_customers,
    SUM(sd.ws_net_profit) AS total_sales_profit,
    STRING_AGG(DISTINCT rp.p_promo_id) AS active_promotions,
    SUM(rd.total_returned) AS total_returns,
    COUNT(DISTINCT rd.sr_customer_sk) AS customers_with_returns
FROM 
    CustomerStats cs
JOIN 
    SalesData sd ON cs.customer_count = sd.ws_order_number
LEFT JOIN 
    RankedPromotions rp ON sd.ws_net_profit > 10000 AND rp.promo_rank = 1
LEFT JOIN 
    ReturnsData rd ON rd.sr_customer_sk = cs.customer_count
WHERE 
    cs.average_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
GROUP BY 
    cs.ca_city, cs.cd_gender
HAVING 
    COUNT(cs.ca_city) > 10 
    AND SUM(sd.ws_net_profit) > (SELECT SUM(ws_net_profit) / 2 FROM web_sales)
ORDER BY 
    total_sales_profit DESC, cs.ca_city, cs.cd_gender;
