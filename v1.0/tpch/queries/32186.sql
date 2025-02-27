WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > 1000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_custkey
),
SupplierAverage AS (
    SELECT ps.ps_partkey, AVG(s.s_acctbal) AS avg_acctbal
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
)
SELECT p.p_name, p.p_retailprice,
       COALESCE(sh.avg_acctbal, 0) AS avg_supplier_acct_bal,
       cnt.cust_count,
       SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue,
       CASE 
           WHEN SUM(lo.l_extendedprice * (1 - lo.l_discount)) IS NULL THEN 'No Revenue'
           ELSE 'Revenue Available'
       END AS revenue_status
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN SupplierAverage sh ON ps.ps_partkey = sh.ps_partkey
LEFT JOIN lineitem lo ON ps.ps_partkey = lo.l_partkey
LEFT JOIN (
    SELECT COUNT(*) AS cust_count, c.c_nationkey
    FROM customer c
    WHERE c.c_acctbal > 1000
    GROUP BY c.c_nationkey
) cnt ON cnt.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
WHERE p.p_size BETWEEN 10 AND 20
GROUP BY p.p_name, p.p_retailprice, cnt.cust_count, sh.avg_acctbal
HAVING SUM(lo.l_extendedprice * (1 - lo.l_discount)) > 5000
ORDER BY total_revenue DESC
LIMIT 100;
