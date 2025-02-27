WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM SupplierHierarchy sh
    JOIN supplier s ON sh.s_nationkey = s.s_nationkey
    WHERE s.s_acctbal > 1000 AND sh.level < 5
),
OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
NationRevenue AS (
    SELECT n.n_nationkey, SUM(os.total_revenue) AS national_revenue
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN OrderStats os ON o.o_orderkey = os.o_orderkey
    GROUP BY n.n_nationkey
),
SupplierPartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ps.ps_supplycost, ps.ps_availqty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size <= 20
    )
)
SELECT SH.s_name, NR.national_revenue, SPD.p_name, SPD.p_retailprice, SPD.ps_supplycost,
       CASE 
           WHEN NR.national_revenue > 50000 THEN 'High Revenue'
           WHEN NR.national_revenue BETWEEN 10000 AND 50000 THEN 'Medium Revenue'
           ELSE 'Low Revenue'
       END AS revenue_category
FROM SupplierHierarchy SH
LEFT JOIN NationRevenue NR ON SH.s_nationkey = NR.n_nationkey
INNER JOIN SupplierPartDetails SPD ON SH.s_suppkey = SPD.ps_partkey
ORDER BY NR.national_revenue DESC, SH.level ASC;
