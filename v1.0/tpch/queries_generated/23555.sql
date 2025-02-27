WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, CAST(s_name AS VARCHAR(100)) AS full_hierarchy
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, CONCAT(sh.full_hierarchy, ' -> ', s.s_name) AS full_hierarchy
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.suppkey <> sh.s_suppkey
), 
CustomerTotalOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), 
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice
    FROM part p
    WHERE p.p_size BETWEEN 10 AND 20
      AND EXISTS (SELECT 1 FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey AND ps.ps_availqty > 0)
), 
RankedCustomers AS (
    SELECT cust.c_custkey, cust.c_name, cust.total_spent, 
           RANK() OVER (ORDER BY cust.total_spent DESC) AS rank
    FROM CustomerTotalOrders cust
    WHERE cust.total_spent IS NOT NULL
), 
SupplierStatistics AS (
    SELECT sh.s_name, AVG(sh.s_acctbal) AS avg_acctbal, COUNT(*) AS supplier_count
    FROM SupplierHierarchy sh
    GROUP BY sh.s_name
)
SELECT DISTINCT rc.c_name,
                COALESCE(p.p_name, 'No Part') AS part_name,
                ss.avg_acctbal,
                ss.supplier_count,
                CASE 
                    WHEN rc.rank <= 10 THEN 'Top Customer'
                    ELSE 'Regular Customer'
                END AS customer_category,
                DATE_TRUNC('MONTH', o.o_orderdate) AS order_month,
                SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM RankedCustomers rc
FULL OUTER JOIN lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = rc.c_custkey)
LEFT JOIN FilteredParts p ON l.l_partkey = p.p_partkey
LEFT JOIN SupplierStatistics ss ON l.l_suppkey = ss.s_suppkey
LEFT JOIN orders o ON rc.c_custkey = o.o_custkey
WHERE o.o_orderstatus = 'O' 
  AND (l.l_shipmode IS NULL OR l.l_shipmode <> 'MAIL')
GROUP BY rc.c_name, p.p_name, ss.avg_acctbal, ss.supplier_count, rc.rank, o.o_orderdate
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) IS NOT NULL
ORDER BY rc.c_name, total_revenue DESC;
