WITH RECURSIVE NationHierarchy AS (
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, 0 AS level
    FROM nation n
    WHERE n.n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON nh.n_nationkey = n.n_regionkey
),
SupplierData AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment,
           ROW_NUMBER() OVER(PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC NULLS LAST) AS rn
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
PartPricing AS (
    SELECT p.p_partkey, p.p_brand, p.p_retailprice, COUNT(ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_brand, p.p_retailprice
),
QualifiedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount,
           COUNT(DISTINCT o.o_custkey) AS total_customers
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND EXTRACT(YEAR FROM o.o_orderdate) = 2023
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT n.n_name, COALESCE(SUM(pd.total_amount), 0) AS total_sales,
       AVG(sp.s_acctbal) AS average_supplier_balance,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY pp.p_retailprice) AS median_price,
       COUNT(DISTINCT sd.s_suppkey) AS unique_suppliers
FROM NationHierarchy n
LEFT JOIN QualifiedOrders pd ON n.n_nationkey = pd.o_orderkey
LEFT JOIN PartPricing pp ON pp.p_partkey IN (SELECT l.l_partkey FROM lineitem l JOIN orders o ON l.l_orderkey = o.o_orderkey WHERE o.o_orderstatus = 'O')
LEFT JOIN SupplierData sd ON sd.s_suppkey = (
    SELECT s.s_suppkey 
    FROM supplier s 
    WHERE s.s_acctbal > 0 AND s.n_nationkey = n.n_nationkey
    ORDER BY s.s_acctbal DESC 
    LIMIT 1 OFFSET (SELECT COUNT(*) FROM supplier WHERE n_nationkey IS NOT NULL) / 2
)
GROUP BY n.n_name
HAVING COUNT(pd.o_orderkey) > 1
ORDER BY total_sales DESC
LIMIT 10;
