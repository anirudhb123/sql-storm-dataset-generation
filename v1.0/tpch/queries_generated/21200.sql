WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
),
HighValueParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS high_value
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > (
        SELECT AVG(AVG(ps_supplycost * ps_availqty))
        FROM partsupp
        GROUP BY ps_partkey
    )
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    r.r_name AS region_name,
    ns.n_name AS nation_name,
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
    SUM(co.total_orders) AS total_customer_orders,
    MAX(php.high_value) AS max_part_value,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM region r
JOIN nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN RankedSuppliers rs ON ns.n_nationkey = rs.s_nationkey AND rs.rnk <= 5
LEFT JOIN partsupp ps ON rs.s_suppkey = ps.ps_suppkey
LEFT JOIN HighValueParts php ON ps.ps_partkey = php.p_partkey
LEFT JOIN CustomerOrders co ON ns.n_nationkey = co.c_custkey
WHERE (COUNT(DISTINCT ps.ps_partkey) > 0 OR php.high_value IS NOT NULL) 
    AND (co.total_orders IS NULL OR co.avg_order_value > 1000)
GROUP BY r.r_name, ns.n_name
HAVING COUNT(DISTINCT ps.ps_suppkey) < 
       (SELECT COUNT(DISTINCT s.s_suppkey) FROM supplier s 
        WHERE s.s_acctbal < 100)
ORDER BY r.r_name, ns.n_name DESC
OFFSET 3 ROWS FETCH NEXT 10 ROWS ONLY;
