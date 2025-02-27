WITH RECURSIVE supplier_parts AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal > 1000.00

    UNION ALL

    SELECT sp.s_suppkey, sp.s_name, ps.ps_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier_parts sp
    JOIN partsupp ps ON sp.ps_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 1000.00 AND sp.s_suppkey != s.s_suppkey
),
region_supplier AS (
    SELECT r.r_regionkey, r.r_name, SUM(sp.ps_supplycost * sp.ps_availqty) AS total_supply_cost
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN supplier_parts sp ON s.s_suppkey = sp.s_suppkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT rs.r_name, rs.total_supply_cost, COUNT(sp.ps_partkey) AS num_parts
FROM region_supplier rs
JOIN supplier_parts sp ON rs.r_regionkey = (
    SELECT n.n_regionkey
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE s.s_suppkey = sp.s_suppkey
)
GROUP BY rs.r_name, rs.total_supply_cost
ORDER BY total_supply_cost DESC, num_parts DESC
LIMIT 10;
