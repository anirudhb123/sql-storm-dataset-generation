WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, ps.ps_partkey
),
HighCostParts AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps_supplycost * ps_availqty) FROM partsupp)
),
TopNations AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN lineitem l ON s.s_suppkey = l.l_suppkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY n.n_nationkey, n.n_name
    ORDER BY order_count DESC
    LIMIT 5
)
SELECT tn.n_name, hp.p_name, rs.s_name, rs.total_cost
FROM TopNations tn
JOIN RankedSuppliers rs ON tn.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = rs.s_suppkey)
JOIN HighCostParts hp ON hp.p_partkey = (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = rs.s_suppkey LIMIT 1)
WHERE tn.order_count > 10
ORDER BY tn.n_name, rs.total_cost DESC;
