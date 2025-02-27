
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        cs_bill_customer_sk, 
        cs_order_number,
        cs_item_sk,
        cs_quantity,
        cs_sales_price,
        cs_ext_sales_price,
        cs_net_paid,
        1 AS level
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk = (SELECT MAX(cs_sold_date_sk) FROM catalog_sales)

    UNION ALL

    SELECT 
        s.ss_customer_sk, 
        s.ss_ticket_number, 
        s.ss_item_sk, 
        s.ss_quantity, 
        s.ss_sales_price, 
        s.ss_ext_sales_price, 
        (sh.cs_net_paid + s.ss_net_paid) AS total_net_paid,
        level + 1
    FROM 
        store_sales s
    JOIN 
        sales_hierarchy sh ON s.ss_customer_sk = sh.cs_bill_customer_sk
    WHERE 
        s.ss_sold_date_sk = sh.cs_order_number
), 
customer_analysis AS (
    SELECT 
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        SUM(sh.cs_quantity) AS total_quantity,
        AVG(sh.cs_sales_price) AS average_sales_price
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        sales_hierarchy sh ON c.c_customer_sk = sh.cs_bill_customer_sk
    GROUP BY 
        ca.ca_city
   HAVING 
        COUNT(DISTINCT c.c_customer_id) > 10
),
promotion_summary AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(cs.cs_net_profit) AS total_profit
    FROM 
        promotion p
    JOIN 
        catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY 
        p.p_promo_id
    HAVING 
        SUM(cs.cs_net_profit) IS NOT NULL
)
SELECT 
    ca.ca_city,
    ca.customer_count,
    ca.total_quantity,
    ca.average_sales_price,
    ps.total_orders,
    ps.total_profit
FROM 
    customer_analysis ca
LEFT JOIN 
    promotion_summary ps ON ca.customer_count > 20
ORDER BY 
    ca.average_sales_price DESC
LIMIT 100;
