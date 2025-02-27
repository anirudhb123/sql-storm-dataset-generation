WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
high_value_customers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > (
        SELECT AVG(c2.c_acctbal) 
        FROM customer c2
        WHERE c2.c_acctbal IS NOT NULL
    )
    GROUP BY c.c_custkey, c.c_name
),
nation_suppliers AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
part_summary AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost 
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)

SELECT sh.s_suppkey, sh.s_name, sh.s_acctbal,
       hvc.c_custkey, hvc.c_name, hvc.total_spent,
       ns.n_name, ns.supplier_count,
       ps.p_partkey, ps.p_name, ps.total_avail_qty, ps.avg_supply_cost
FROM supplier_hierarchy sh
FULL OUTER JOIN high_value_customers hvc ON sh.rank = 1 AND hvc.total_spent IS NOT NULL
LEFT JOIN nation_suppliers ns ON ns.supplier_count > (
    SELECT COUNT(*) 
    FROM supplier 
    WHERE s_acctbal > 1000
)
RIGHT JOIN part_summary ps ON ps.total_avail_qty > (
    SELECT MIN(ps_total) FROM (
        SELECT SUM(ps.ps_availqty) AS ps_total 
        FROM partsupp ps 
        GROUP BY ps.ps_partkey
    ) AS subquery
) OR ps.avg_supply_cost IS NULL
WHERE sh.s_acctbal IS NOT NULL AND hvc.total_spent IS NOT NULL
ORDER BY sh.s_acctbal DESC, hvc.total_spent DESC, ns.n_name, ps.p_partkey
FETCH FIRST 100 ROWS ONLY;
