WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal >= 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.suppkey <> sh.s_suppkey AND s.s_acctbal < sh.level * 10000
),
part_statistics AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
customer_summary AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    ps.total_avail_qty,
    ps.avg_supply_cost,
    cs.total_spent,
    cs.order_count,
    COUNT(sh.s_suppkey) AS supplier_count,
    RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_discount) DESC) AS discount_rank
FROM part p
LEFT JOIN part_statistics ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN customer_summary cs ON cs.total_spent IS NOT NULL
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = (
    SELECT n.n_nationkey
    FROM nation n
    JOIN supplier su ON su.s_nationkey = n.n_nationkey
    WHERE su.s_suppkey = l.l_suppkey
)
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    p.p_retailprice, 
    ps.total_avail_qty, 
    ps.avg_supply_cost, 
    cs.total_spent, 
    cs.order_count
HAVING 
    (ps.total_avail_qty > 1000 OR cs.order_count > 5)
ORDER BY 
    discount_rank DESC, 
    p.p_retailprice ASC;
