WITH RankedParts AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, COUNT(ps.ps_partkey) AS parts_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING COUNT(ps.ps_partkey) > 10
),
OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY o.o_orderkey
),
RegionNation AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT rp.p_name, rs.s_name, os.total_revenue, rn.r_name
FROM RankedParts rp
JOIN TopSuppliers rs ON rp.p_partkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps
    WHERE ps.ps_suppkey = rs.s_suppkey
)
JOIN OrderStats os ON rp.p_partkey IN (
    SELECT l.l_partkey
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderkey = os.o_orderkey
)
JOIN RegionNation rn ON rs.parts_count > 15
ORDER BY os.total_revenue DESC, rp.total_supply_cost ASC
LIMIT 100;
