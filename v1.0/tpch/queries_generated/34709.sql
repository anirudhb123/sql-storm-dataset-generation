WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 as level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal <= 10000
),
CustomerOrderDetails AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) as rnk
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
),
NationStats AS (
    SELECT n.n_nationkey, n.n_name, COUNT(s.s_suppkey) as supplier_count,
           AVG(s.s_acctbal) as avg_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    ph.p_partkey,
    ph.p_name,
    ph.p_brand,
    ph.p_retailprice,
    coalesce(n_avg.avg_acctbal, 0) as avg_supplier_acctbal,
    cs.c_custkey,
    cs.c_name,
    cs.o_orderkey,
    cs.o_totalprice,
    CASE WHEN cs.rnk = 1 THEN 'Latest Order' ELSE 'Previous Order' END as order_status
FROM
    part ph
LEFT JOIN partsupp p ON ph.p_partkey = p.ps_partkey
LEFT JOIN SupplierHierarchy sh ON p.ps_suppkey = sh.s_suppkey
LEFT JOIN NationStats n_avg ON sh.s_nationkey = n_avg.n_nationkey
LEFT JOIN CustomerOrderDetails cs ON cs.o_orderkey IN (
    SELECT l.l_orderkey
    FROM lineitem l
    WHERE l.l_partkey = ph.p_partkey AND l.l_discount > 0.05
)
WHERE ph.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice < 100)
ORDER BY ph.p_partkey, cs.o_totalprice DESC;
