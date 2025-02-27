WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 1 AS depth
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal * 1.1 AS s_acctbal, s.s_nationkey, sh.depth + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.depth < 5
),
PartSupplierStats AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_availqty, 
           AVG(ps.ps_supplycost) AS avg_supplycost, 
           COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ps.total_availqty, 
           RANK() OVER (ORDER BY ps.total_availqty DESC) AS rank
    FROM part p
    JOIN PartSupplierStats ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice BETWEEN 10 AND 100
)
SELECT t.p_partkey, t.p_name, t.p_retailprice, t.total_availqty,
       CASE
           WHEN t.rank <= 10 THEN 'Top Part'
           WHEN t.total_availqty IS NULL THEN 'No Supply'
           ELSE 'Average Part'
       END AS part_category,
       COALESCE((SELECT STRING_AGG(s.s_name, ', ') 
                 FROM supplier s 
                 WHERE s.s_nationkey = (SELECT n.n_nationkey 
                                         FROM nation n 
                                         WHERE n.n_name = 'GERMANY')), 'No Supplier') AS supplier_names,
       DENSE_RANK() OVER (PARTITION BY t.total_availqty ORDER BY t.p_retailprice DESC) AS price_rank
FROM TopParts t
LEFT JOIN region r ON r.r_regionkey = (SELECT n.n_regionkey 
                                        FROM nation n 
                                        WHERE n.n_nationkey IN 
                                            (SELECT c.c_nationkey 
                                             FROM customer c 
                                             WHERE c.c_acctbal BETWEEN 1000 AND 5000))
WHERE r.r_name IS NOT NULL
ORDER BY t.rank, t.p_retailprice DESC
FETCH FIRST 100 ROWS ONLY;
