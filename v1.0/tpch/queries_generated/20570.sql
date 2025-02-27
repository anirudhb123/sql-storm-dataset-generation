WITH RECURSIVE SuppCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
RegionSum AS (
    SELECT n.n_regionkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE p.p_size BETWEEN 20 AND 50
    GROUP BY n.n_regionkey
),
CustomerOrders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus = 'O'
    GROUP BY c.c_custkey
    HAVING COUNT(o.o_orderkey) > 0
)
SELECT 
    r.r_name, 
    COALESCE(rs.total_cost, 0) AS total_region_cost,
    SUM(CASE WHEN co.order_count > 5 THEN co.order_count ELSE 0 END) AS high_volume_customers,
    COUNT(DISTINCT ss.s_suppkey) AS distinct_suppliers
FROM region r
LEFT JOIN RegionSum rs ON r.r_regionkey = rs.n_regionkey
LEFT JOIN CustomerOrders co ON co.c_custkey IN (
    SELECT c.c_custkey 
    FROM customer c 
    WHERE c.c_acctbal IS NOT NULL
    AND c.c_mktsegment LIKE 'AUTOMOBILE%'
)
LEFT JOIN SuppCTE ss ON ss.rn = 1
WHERE r.r_name IS NOT NULL AND r.r_name <> ''
GROUP BY r.r_name
ORDER BY total_region_cost DESC, high_volume_customers DESC
LIMIT 10 OFFSET 5;
