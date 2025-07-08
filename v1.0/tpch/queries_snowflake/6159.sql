WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
TopNations AS (
    SELECT n.n_nationkey, n.n_name, SUM(o.o_totalprice) AS total_revenue
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN customer c ON s.s_suppkey = c.c_custkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING SUM(o.o_totalprice) > 1000000
),
PartStatistics AS (
    SELECT p.p_partkey, p.p_name, COUNT(ps.ps_availqty) AS supplier_count, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT R.s_name AS supplier_name,
       R.total_supply_cost,
       T.n_name AS nation_name,
       P.p_name AS part_name,
       P.supplier_count,
       P.avg_supply_cost
FROM RankedSuppliers R
JOIN TopNations T ON R.s_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = T.n_nationkey)
JOIN PartStatistics P ON P.supplier_count > 5
WHERE R.total_supply_cost > 50000
ORDER BY R.total_supply_cost DESC, T.total_revenue DESC, P.avg_supply_cost ASC;
