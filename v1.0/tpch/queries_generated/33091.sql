WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_nationkey <> 0
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    INNER JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
total_ordered AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
part_supplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty * ps.ps_supplycost) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
detailed_info AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ps.total_cost,
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    LEFT JOIN part_supplier ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
final_report AS (
    SELECT n.n_name, d.p_name, d.p_retailprice, d.total_cost,
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY d.total_cost DESC) AS nation_rank
    FROM detailed_info d
    JOIN nation_hierarchy n ON n.n_nationkey IN (SELECT s.s_nationkey FROM supplier s)
    WHERE d.rank <= 5
)
SELECT fr.n_name, fr.p_name, fr.p_retailprice, fr.total_cost
FROM final_report fr
WHERE fr.total_cost IS NOT NULL
ORDER BY fr.n_name, fr.total_cost DESC;
