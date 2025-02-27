WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 as level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey OR sh.level = 0
    WHERE sh.level < 3
),
part_supplier_agg AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost, 
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           CASE WHEN SUM(ps.ps_availqty) > 100 THEN 'High' ELSE 'Low' END AS availability,
           MAX(ps.ps_supplycost) AS max_supply_cost,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
customer_order_stats AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spending,
           DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT p.p_name, ps.total_supply_cost, ps.availability, cs.order_count, 
       CASE WHEN cs.order_count > 0 THEN cs.total_spending ELSE NULL END AS total_spending,
       ROW_NUMBER() OVER (PARTITION BY cs.spending_rank ORDER BY ps.max_supply_cost DESC) AS rank_by_cost
FROM part_supplier_agg ps
JOIN part p ON p.p_partkey = ps.ps_partkey
LEFT JOIN customer_order_stats cs ON cs.order_count IS NOT NULL
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size IS NOT NULL)
      OR p.p_mfgr IS NULL
ORDER BY p.p_name, ps.total_supply_cost DESC
FETCH FIRST 100 ROWS ONLY;
