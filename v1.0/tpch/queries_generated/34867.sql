WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_availqty < 50)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_suppkey <> sh.s_suppkey
),
PartAvailability AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_avail
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_orderdate
),
CustomerPurchaseFrequency AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS purchase_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    INNER JOIN region r ON n.n_regionkey = r.r_regionkey
),
SupplierRevenue AS (
    SELECT sh.s_suppkey, SUM(os.total_revenue) AS supplier_revenue
    FROM SupplierHierarchy sh
    JOIN OrderStats os ON sh.s_suppkey = os.o_orderkey
    GROUP BY sh.s_suppkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    pa.total_avail,
    SUM(sr.supplier_revenue) AS total_supplier_revenue,
    COALESCE(SUM(cp.purchase_count), 0) AS customer_purchase_count,
    n.n_name AS nation_name,
    r.r_name AS region_name
FROM part p
LEFT JOIN PartAvailability pa ON p.p_partkey = pa.p_partkey
LEFT JOIN SupplierRevenue sr ON sr.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey)
LEFT JOIN CustomerPurchaseFrequency cp ON cp.c_custkey IN 
    (SELECT o.o_custkey FROM orders o JOIN lineitem l ON o.o_orderkey = l.l_orderkey WHERE l.l_partkey = p.p_partkey AND o.o_orderstatus = 'O')
JOIN NationRegion n ON n.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = sr.s_suppkey)
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
GROUP BY p.p_partkey, p.p_name, pa.total_avail, n.n_name, r.r_name
ORDER BY total_supplier_revenue DESC, customer_purchase_count DESC;
