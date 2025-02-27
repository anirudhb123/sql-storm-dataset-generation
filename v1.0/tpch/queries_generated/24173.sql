WITH RECURSIVE TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
ProductInfo AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
           CASE
               WHEN p.p_size > 50 THEN 'Large'
               WHEN p.p_size BETWEEN 20 AND 50 THEN 'Medium'
               ELSE 'Small'
           END AS size_category
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
),
CustomerSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) as order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierPartStats AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           SUM(ps.ps_availqty) AS total_available, 
           SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
DetailedAnalysis AS (
    SELECT p.p_partkey, p.p_name, pi.size_category, 
           COALESCE(sp.total_available, 0) AS total_available, 
           sp.total_supplycost, 
           cs.total_spent, 
           cs.order_count,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY cs.total_spent DESC) AS customer_rank
    FROM ProductInfo p
    LEFT JOIN SupplierPartStats sp ON p.p_partkey = sp.ps_partkey
    LEFT JOIN CustomerSummary cs ON sp.ps_suppkey = cs.c_custkey
)
SELECT d.p_partkey, d.p_name, d.size_category, d.total_available, 
       d.total_supplycost, COALESCE(d.total_spent, 0) AS total_spent,
       (d.total_supplycost / NULLIF(d.total_available, 0)) AS cost_per_unit,
       d.customer_rank
FROM DetailedAnalysis d
WHERE d.customer_rank = 1 OR d.total_available > 50
ORDER BY d.total_spent DESC, d.total_available ASC;
