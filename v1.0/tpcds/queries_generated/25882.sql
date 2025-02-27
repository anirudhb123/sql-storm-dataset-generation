
WITH RankedCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        STRING_AGG(DISTINCT CONCAT(pt.p_promo_name, ' (', p.p_discount_active, ')'), '; ') AS promotional_interactions
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN
        (SELECT
            cs_bill_customer_sk,
            p.promo_name AS p_promo_name,
            p.p_discount_active
        FROM
            catalog_sales cs
        JOIN
            promotion p ON cs.cs_promo_sk = p.p_promo_sk
        WHERE
            p.p_discount_active = 'Y') pt ON c.c_customer_sk = pt.cs_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    rc.c_customer_sk,
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.order_count,
    rc.promotional_interactions,
    RANK() OVER (ORDER BY rc.order_count DESC) AS rank_by_orders
FROM 
    RankedCustomers rc
WHERE 
    rc.order_count > 5
ORDER BY 
    rank_by_orders, rc.c_last_name, rc.c_first_name;
