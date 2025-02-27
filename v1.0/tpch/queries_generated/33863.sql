WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
TotalLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    GROUP BY l.l_orderkey
),
MaxSalesPerCustomer AS (
    SELECT o.o_custkey, MAX(t.total_sales) AS max_sales
    FROM orders o
    JOIN TotalLineItems t ON o.o_orderkey = t.l_orderkey
    GROUP BY o.o_custkey
),
SupplierSales AS (
    SELECT s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name
),
RankedSuppliers AS (
    SELECT s.s_name, ss.total_supply_cost, RANK() OVER (ORDER BY ss.total_supply_cost DESC) AS supplier_rank
    FROM SupplierSales ss
    JOIN supplier s ON ss.s_name = s.s_name
),
CustomerSales AS (
    SELECT c.c_custkey, SUM(t.total_sales) AS customer_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN TotalLineItems t ON o.o_orderkey = t.l_orderkey
    GROUP BY c.c_custkey
)
SELECT r.r_name, COUNT(DISTINCT c.c_custkey) AS customer_count, 
       AVG(cs.customer_sales) AS average_customer_sales,
       MAX(ss.total_supply_cost) AS max_supply_cost,
       STRING_AGG(DISTINCT sh.s_name, ', ') AS suppliers
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN CustomerSales cs ON c.c_custkey = cs.c_custkey
LEFT JOIN RankedSuppliers ss ON ss.supplier_rank <= 5
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = ss.s_name
WHERE cs.customer_sales IS NOT NULL OR ss.total_supply_cost IS NOT NULL
GROUP BY r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 10
ORDER BY average_customer_sales DESC;
