WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
), high_value_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_name,
           ROW_NUMBER() OVER (PARTITION BY c.custkey ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
), supplier_inventory AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ps.ps_availqty,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost) AS rn_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
), filtered_regions AS (
    SELECT r.r_regionkey, r.r_name
    FROM region r
    WHERE LENGTH(r.r_name) BETWEEN 5 AND 10
)

SELECT DISTINCT s.s_name, h.o_orderkey, h.o_totalprice, si.p_name,
                COALESCE(AVG(si.ps_availqty), 0) AS avg_availqty,
                COUNT(DISTINCT h.c_name) AS num_customers
FROM supplier_hierarchy s
LEFT JOIN high_value_orders h ON s.s_nationkey = h.c_name
LEFT JOIN supplier_inventory si ON s.s_suppkey = si.p_partkey
FULL OUTER JOIN filtered_regions r ON s.s_nationkey = r.r_regionkey
WHERE (s.s_name IS NOT NULL AND h.o_orderkey IS NOT NULL)
AND (h.o_totalprice > 1000 OR si.p_retailprice < 10)
GROUP BY s.s_name, h.o_orderkey, h.o_totalprice, si.p_name
HAVING COUNT(si.ps_availqty) > 1
ORDER BY num_customers DESC, avg_availqty ASC;
