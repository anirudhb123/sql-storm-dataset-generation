WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey) AS supply_count
    FROM supplier s
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey) AS supply_count
    FROM supplier s
    JOIN supplier_hierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE sh.s_acctbal > 10000
),
top_customers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           DENSE_RANK() OVER (ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),
part_supplier AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, ps.ps_supplycost,
           ps.ps_availqty, p.p_retailprice,
           (p.p_retailprice * ps.ps_availqty) AS potential_revenue,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    SUM(CASE WHEN li.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count,
    AVG(potential_revenue) AS avg_potential_revenue,
    SUM(CASE WHEN c.c_mktsegment = 'TOOL' THEN 1 ELSE 0 END) AS tool_customers,
    (SELECT COUNT(DISTINCT l_orderkey) 
     FROM lineitem l
     WHERE l.l_returnflag IS NOT NULL
       AND EXISTS (
           SELECT 1 
           FROM orders o
           WHERE o.o_orderkey = l.l_orderkey
             AND o.o_orderstatus = 'F'
       )) AS finalized_active_orders
FROM nation n
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN top_customers tc ON tc.c_custkey IN (
    SELECT DISTINCT c.c_custkey 
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN '2021-01-01' AND '2021-12-31'
)
LEFT JOIN part_supplier ps ON ps.ps_supplycost > (
    SELECT AVG(ps2.ps_supplycost)
    FROM partsupp ps2
)
LEFT JOIN lineitem li ON li.l_partkey IN (
    SELECT p_partkey FROM part WHERE p_brand LIKE 'Brand#%'
)
GROUP BY n.n_name, r.r_name
HAVING AVG(ps.ps_supplycost) IS NOT NULL
ORDER BY return_count DESC, avg_potential_revenue ASC;
