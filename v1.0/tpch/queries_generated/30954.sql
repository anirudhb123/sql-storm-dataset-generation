WITH RecursivePartSupply AS (
    SELECT ps.partkey, ps.suppkey, ps.availqty, ps.supplycost, 1 AS level
    FROM partsupp ps
    WHERE ps.availqty > 0
    UNION ALL
    SELECT ps.partkey, ps.suppkey, ps.availqty - 1, ps.supplycost, level + 1
    FROM partsupp ps
    INNER JOIN RecursivePartSupply rps ON ps.partkey = rps.partkey AND ps.suppkey = rps.suppkey
    WHERE rps.availqty > 1 AND level < 5
),
TotalOrderValue AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
SupplierRegion AS (
    SELECT s.s_suppkey, r.r_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, r.r_name
)
SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.suppkey) AS unique_suppliers,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    COALESCE(SUM(t.total_value), 0) AS total_order_value,
    sr.total_supplycost AS region_supply_cost,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY AVG(ps.ps_supplycost) DESC) AS rank
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN TotalOrderValue t ON p.p_partkey = t.o_orderkey
LEFT JOIN SupplierRegion sr ON ps.ps_suppkey = sr.s_suppkey
LEFT JOIN nation n ON ps.ps_suppkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_size > 10 AND (p.p_retailprice IS NOT NULL OR p.p_comment IS NOT NULL)
GROUP BY p.p_name, sr.total_supplycost, r.r_name
HAVING unique_suppliers > 0 AND avg_supply_cost < 100.00
ORDER BY rank, p.p_name;
