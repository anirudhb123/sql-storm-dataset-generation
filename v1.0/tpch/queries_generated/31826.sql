WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
TopPartSuppliers AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
    HAVING SUM(ps.ps_supplycost) > 5000
),
OrderedCustomerSales AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey
),
PartSales AS (
    SELECT p.p_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY p.p_partkey
),
FinalSales AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.total_supplycost, ps_availqty, 
           COALESCE(oc.total_sales, 0) AS customer_sales, 
           COALESCE(p.total_revenue, 0) AS part_revenue
    FROM TopPartSuppliers ps
    LEFT JOIN (SELECT ps.partkey, SUM(ps.ps_availqty) AS ps_availqty FROM partsupp ps GROUP BY ps.ps_partkey) AS supplier_avail ON ps.ps_partkey = supplier_avail.partkey
    LEFT JOIN OrderedCustomerSales oc ON ps.ps_suppkey = oc.c_custkey
    LEFT JOIN PartSales p ON ps.ps_partkey = p.p_partkey
)
SELECT f.ps_partkey, f.ps_suppkey, f.total_supplycost, f.customer_sales, f.part_revenue, 
       (CASE 
           WHEN f.customer_sales > f.part_revenue THEN 'High Demand'
           ELSE 'Low Demand'
        END) AS demand_status
FROM FinalSales f
WHERE (f.customer_sales IS NOT NULL OR f.part_revenue IS NOT NULL)
ORDER BY f.total_supplycost DESC
LIMIT 50;
