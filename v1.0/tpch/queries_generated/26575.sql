WITH StringManipulation AS (
    SELECT 
        p.p_partkey,
        UPPER(p.p_name) AS upper_name,
        LOWER(p.p_comment) AS lower_comment,
        CONCAT(p.p_mfgr, ' - ', p.p_brand) AS mfgr_brand_combined,
        LENGTH(p.p_container) AS container_length,
        REPLACE(p.p_comment, 'nice', 'excellent') AS updated_comment,
        SUBSTRING(p.p_name, 1, 10) AS short_name
    FROM part p
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    sm.upper_name,
    sm.lower_comment,
    sm.mfgr_brand_combined,
    sm.container_length,
    sm.updated_comment,
    sm.short_name,
    co.c_name AS customer_name,
    co.order_count,
    co.total_spent
FROM StringManipulation sm 
JOIN CustomerOrders co ON sm.p_partkey % 100 = co.c_custkey % 100
WHERE sm.container_length > 5 
ORDER BY co.total_spent DESC, sm.upper_name;
