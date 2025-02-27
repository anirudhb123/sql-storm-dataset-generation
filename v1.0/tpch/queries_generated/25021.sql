WITH SupplierPartCounts AS (
    SELECT 
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        STRING_AGG(DISTINCT CONCAT_WS(' - ', p.p_name, p.p_brand)) AS part_names_brands
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_name
),

CustomerOrders AS (
    SELECT 
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_name
),

CombinedMetrics AS (
    SELECT 
        spc.s_name,
        spc.part_count,
        spc.part_names_brands,
        co.order_count,
        co.total_spent
    FROM SupplierPartCounts spc
    JOIN CustomerOrders co ON CHAR_LENGTH(spc.s_name) = CHAR_LENGTH(co.c_name) -- matching string lengths for fun
)

SELECT 
    s_name,
    part_count,
    part_names_brands,
    order_count,
    total_spent,
    CONCAT('Supplier ', s_name, ' has ', part_count, ' parts: ', part_names_brands, ' and supported ', order_count, ' orders totaling ', total_spent) AS summary
FROM CombinedMetrics
WHERE part_count > 5 AND order_count > 10
ORDER BY total_spent DESC
LIMIT 10;
