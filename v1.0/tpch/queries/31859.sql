WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal > sh.s_acctbal * 0.9
),
AvgOrderValue AS (
    SELECT o.o_custkey, AVG(o.o_totalprice) AS avg_value
    FROM orders o
    GROUP BY o.o_custkey
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
SupplierCounts AS (
    SELECT n.n_name, COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
MaxDiscounts AS (
    SELECT l.l_partkey, MAX(l.l_discount) AS max_discount
    FROM lineitem l
    GROUP BY l.l_partkey
)

SELECT 
    p.p_name,
    CASE 
        WHEN AVG(o.o_totalprice) IS NULL THEN 'No Orders'
        ELSE CONCAT('Avg: $', ROUND(AVG(o.o_totalprice), 2))
    END AS avg_order_price,
    COALESCE(sc.supplier_count, 0) AS num_suppliers,
    psi.total_supply_cost,
    md.max_discount,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY psi.total_supply_cost DESC) AS rank
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN SupplierCounts sc ON p.p_brand = sc.n_name
JOIN PartSupplierInfo psi ON p.p_partkey = psi.p_partkey
LEFT JOIN MaxDiscounts md ON p.p_partkey = md.l_partkey
JOIN region r ON EXISTS (
    SELECT 1
    FROM nation n
    WHERE n.n_nationkey = sc.supplier_count
    AND n.n_regionkey = r.r_regionkey
)
WHERE p.p_retailprice > 20.00
GROUP BY p.p_name, sc.supplier_count, psi.total_supply_cost, md.max_discount, r.r_name
HAVING COUNT(o.o_orderkey) > 5
ORDER BY rank, p.p_name;
