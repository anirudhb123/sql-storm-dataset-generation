WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, p.p_brand, p.p_type, ps.ps_supplycost, ps.ps_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA'))
    UNION ALL
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, p.p_brand, p.p_type, ps.ps_supplycost, ps.ps_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
)
SELECT sh.s_name, sh.p_name, SUM(sh.ps_supplycost * sh.ps_availqty) AS total_supply_cost
FROM supplier_hierarchy sh
GROUP BY sh.s_name, sh.p_name
HAVING SUM(sh.ps_supplycost * sh.ps_availqty) > (
    SELECT AVG(SUM(ps.ps_supplycost * ps.ps_availqty))
    FROM partsupp ps
    GROUP BY ps.ps_partkey
) 
ORDER BY total_supply_cost DESC
LIMIT 10;
