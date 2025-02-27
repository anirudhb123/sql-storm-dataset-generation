
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.level * 1000
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
),
SupplierProducts AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, SUM(l.l_quantity) AS total_quantity
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN lineitem l ON ps.ps_suppkey = l.l_suppkey
    WHERE p.p_retailprice > 50 AND l.l_returnflag = 'N'
    GROUP BY p.p_partkey, p.p_name, ps.ps_supplycost
),
OrdersSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS ranked_price
    FROM orders o
)
SELECT 
    r.r_name,
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    COALESCE(MAX(sp.total_quantity), 0) AS max_product_quantity,
    SUM(os.o_totalprice) AS total_order_value
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN CustomerOrders c ON c.order_count > 0
LEFT JOIN SupplierProducts sp ON sp.p_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_mfgr = 'ManufacturerX')
LEFT JOIN OrdersSummary os ON os.o_orderkey = (SELECT MIN(o.o_orderkey) FROM orders o WHERE o.o_orderdate = '1996-12-31')
WHERE n.n_comment IS NOT NULL
GROUP BY r.r_name, n.n_name
HAVING SUM(os.o_totalprice) > 10000
ORDER BY r.r_name, n.n_name;
