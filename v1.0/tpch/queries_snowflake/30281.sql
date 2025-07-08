
WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT ps.ps_suppkey, s.s_name, s.s_acctbal, sc.level + 1
    FROM SupplyChain sc
    JOIN partsupp ps ON sc.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 5000 AND sc.level < 10
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM orders o
    WHERE o.o_orderdate >= DATE '1998-10-01' - INTERVAL '30 days'
),
TopNations AS (
    SELECT n.n_nationkey, SUM(o.o_totalprice) AS total_sales
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_nationkey
    ORDER BY total_sales DESC
    LIMIT 5
),
SupplierPerformance AS (
    SELECT s.s_suppkey, s.s_name, COUNT(DISTINCT ps.ps_partkey) AS part_count, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT 
    sc.s_suppkey AS supplier_id,
    sc.s_name AS supplier_name,
    COALESCE(sp.part_count, 0) AS parts_supplied,
    COALESCE(sp.total_supply_cost, 0.00) AS total_supply_cost,
    rn.n_name AS nation_name,
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice
FROM SupplyChain sc
LEFT JOIN SupplierPerformance sp ON sc.s_suppkey = sp.s_suppkey
JOIN TopNations tn ON sc.s_suppkey IN (
    SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (
        SELECT p.p_partkey FROM part p WHERE p.p_retailprice > 50.00
    )
)
LEFT JOIN nation rn ON sc.level = rn.n_nationkey
JOIN RecentOrders ro ON sc.s_suppkey = ro.o_orderkey
WHERE (sc.level IS NOT NULL OR sc.s_name IS NOT NULL)
ORDER BY total_supply_cost DESC, ro.o_orderdate DESC;
