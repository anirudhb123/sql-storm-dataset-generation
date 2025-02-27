WITH RECURSIVE Nationals AS (
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, 0 AS depth
    FROM nation n
    WHERE n.n_name LIKE 'A%'
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, depth + 1
    FROM nation n
    JOIN Nationals nat ON n.n_regionkey = nat.n_regionkey
    WHERE nat.depth < 3
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS price_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
)
SELECT r.r_name, ns.n_name, ss.s_name, ds.total_price
FROM region r
LEFT JOIN Nationals ns ON r.r_regionkey = ns.n_regionkey
FULL OUTER JOIN SupplierStats ss ON ns.n_nationkey = ss.s_suppkey
JOIN OrderDetails ds ON ds.o_orderkey = ss.s_suppkey
WHERE r.r_name IS NOT NULL AND ss.total_supply_cost IS NOT NULL
  AND (ds.price_rank = 1 OR (ss.part_count > 5 AND ds.total_price > 1000))
ORDER BY r.r_name, ns.n_name, ds.total_price DESC, ss.s_name
FETCH FIRST 100 ROWS ONLY
OFFSET (SELECT COUNT(*) FROM supplier) ROWS
EXCEPT
SELECT NULL, NULL, NULL, NULL
WHERE EXISTS (SELECT 1 FROM customer c WHERE c.c_acctbal IS NULL);
