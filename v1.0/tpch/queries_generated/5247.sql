WITH NationStats AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count, SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
), 
PartStats AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
), 
TopRegions AS (
    SELECT r.r_name, SUM(ps.ps_availqty) AS total_available_qty
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY r.r_name
    ORDER BY total_available_qty DESC
    LIMIT 5
)
SELECT ns.n_name, ns.supplier_count, ns.total_acctbal, ps.p_name, ps.avg_supply_cost, tr.r_name, tr.total_available_qty
FROM NationStats ns
JOIN PartStats ps ON ps.avg_supply_cost > (SELECT AVG(avg_supply_cost) FROM PartStats)
JOIN TopRegions tr ON tr.total_available_qty > 1000
ORDER BY ns.total_acctbal DESC, ps.avg_supply_cost ASC;
