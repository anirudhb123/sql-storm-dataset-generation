WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'Germany')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
),
TopPartSuppliers AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
    HAVING SUM(ps.ps_supplycost) > 1000
),
PartSales AS (
    SELECT p.p_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey
),
RankedParts AS (
    SELECT ps.p_partkey, ps.total_sales, ROW_NUMBER() OVER (ORDER BY ps.total_sales DESC) AS rank
    FROM PartSales ps
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(SH.s_acctbal) AS avg_supplier_acctbal,
    SUM(ps.total_supply_cost) AS total_supply_cost,
    COALESCE(SUM(rp.total_sales), 0) AS total_sales,
    STRING_AGG(DISTINCT p.p_name, ', ') AS involved_parts
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierHierarchy SH ON s.s_suppkey = SH.s_suppkey
LEFT JOIN TopPartSuppliers ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN RankedParts rp ON ps.ps_partkey = rp.p_partkey
LEFT JOIN CustomerOrders c ON c.c_custkey = SH.s_nationkey
WHERE r.r_name IS NOT NULL 
GROUP BY r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 5
ORDER BY total_sales DESC;
