WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) -- Selecting suppliers with above-average account balance
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier h JOIN partsupp ps ON h.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_partkey = s.s_suppkey
    JOIN supplier_hierarchy sh ON h.s_suppkey = sh.s_suppkey
    WHERE sh.level < 5
),
part_details AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL AND p.p_retailprice > 100
),
region_nation AS (
    SELECT n.n_nationkey, n.n_name, r.r_name, 
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
    HAVING COUNT(s.s_suppkey) > 0
),
order_summary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent,
           DENSE_RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= '2023-01-01'
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.n_name, r.r_name, ph.p_name, ph.brand_rank, os.c_name, os.total_orders, os.total_spent,
       sh.level AS supplier_hierarchy_level
FROM region_nation r
JOIN part_details ph ON ph.brand_rank <= 5
JOIN order_summary os ON os.total_orders > 10
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = r.n_nationkey
ORDER BY r.r_name, os.total_spent DESC, ph.p_retailprice DESC;
