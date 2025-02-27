WITH RECURSIVE NationHierarchy AS (
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, 1 AS level
    FROM nation n
    WHERE n.n_name = 'FRANCE'
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
PartSupplierStats AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
TopProducts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice
    FROM part p
    JOIN PartSupplierStats ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.supplier_count > 5 AND ps.total_available > 100
    ORDER BY p.p_retailprice DESC
    LIMIT 10
)
SELECT c.c_name AS customer_name, 
       SUM(o.o_totalprice) AS total_spent,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
WHERE EXISTS (SELECT 1 FROM NationHierarchy nh WHERE nh.n_nationkey = c.c_nationkey)
GROUP BY c.c_name, c.c_nationkey
HAVING SUM(o.o_totalprice) IS NOT NULL AND COUNT(o.o_orderkey) > 0
ORDER BY total_spent DESC;

-- Adding a UNION for additional insights
SELECT 'Average' AS detail_type, 
       AVG(o.o_totalprice) AS average_spent,
       COUNT(DISTINCT o.o_orderkey) AS average_order_count
FROM orders o
WHERE o.o_orderstatus = 'O'
GROUP BY 'Average';
