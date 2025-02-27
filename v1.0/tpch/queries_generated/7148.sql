WITH region_summary AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count,
           SUM(s.s_acctbal) AS total_acctbal
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
),
part_suppliers AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS available_quantity,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
order_summary AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_custkey
)
SELECT rs.r_name, rs.nation_count, rs.total_acctbal,
       ps.p_name, ps.available_quantity, ps.avg_supply_cost,
       os.total_spent
FROM region_summary rs
JOIN part_suppliers ps ON ps.available_quantity > (SELECT AVG(available_quantity) FROM part_suppliers)
LEFT JOIN order_summary os ON os.total_spent > (SELECT AVG(total_spent) FROM order_summary)
ORDER BY rs.total_acctbal DESC, os.total_spent DESC
LIMIT 100;
