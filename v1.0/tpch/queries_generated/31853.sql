WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT ps.ps_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN SupplierHierarchy sh ON ps.ps_partkey = sh.s_suppkey
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent,
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS nation_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           (CASE 
                WHEN p.p_retailprice < 20 THEN 'Low'
                WHEN p.p_retailprice BETWEEN 20 AND 50 THEN 'Medium'
                ELSE 'High'
           END) AS price_category
    FROM part p
    WHERE p.p_size IS NOT NULL
),
AggregateLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate >= '2022-01-01'
    GROUP BY l.l_orderkey
)
SELECT c.c_name AS customer_name, 
       COALESCE(cos.order_count, 0) AS order_count, 
       COALESCE(cos.total_spent, 0) AS total_spent,
       ph.p_name AS popular_part,
       sp.s_name AS supplier_name,
       sh.level AS supplier_level
FROM CustomerOrderStats cos
FULL OUTER JOIN FilteredParts ph ON cos.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = (SELECT MAX(o2.o_orderkey) FROM orders o2 WHERE o2.o_custkey = cos.c_custkey))
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = ph.p_partkey LIMIT 1)
LEFT JOIN supplier sp ON sp.s_suppkey = sh.s_suppkey
WHERE cos.nation_rank <= 5 OR cos.nation_rank IS NULL
ORDER BY total_spent DESC NULLS LAST;
