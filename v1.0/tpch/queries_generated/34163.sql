WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_suppkey <> sh.s_suppkey AND sh.level < 5
),
TotalSales AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate > '2022-01-01'
    GROUP BY l.l_orderkey
),
CustomerOrders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > 50
    GROUP BY p.p_partkey, p.p_name
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
)
SELECT 
    COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
    s.s_name AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    COUNT(DISTINCT p.p_partkey) AS total_parts,
    MAX(s.s_acctbal) AS max_supplier_balance,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) = 0 THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status
FROM CustomerOrders co
LEFT JOIN customer c ON co.c_custkey = c.c_custkey
LEFT JOIN orders o ON o.o_custkey = c.c_custkey
LEFT JOIN lineitem l ON l.l_orderkey = o.o_orderkey
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = c.c_nationkey
LEFT JOIN FilteredParts p ON p.p_partkey = l.l_partkey
LEFT JOIN supplier s ON s.s_suppkey = l.l_suppkey
WHERE sh.level IS NOT NULL
GROUP BY c.c_name, s.s_name
HAVING SUM(l.l_extendedprice) > 1000 OR COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_sales DESC
LIMIT 10;
