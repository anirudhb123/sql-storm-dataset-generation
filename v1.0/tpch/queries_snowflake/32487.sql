WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_name, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
TotalSales AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    GROUP BY l.l_orderkey
),
SupplierSales AS (
    SELECT sh.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    GROUP BY sh.s_name
)
SELECT 
    od.o_orderkey,
    od.o_totalprice,
    od.c_name,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
    ROW_NUMBER() OVER (ORDER BY od.o_totalprice DESC) AS order_rank
FROM OrderDetails od
LEFT JOIN TotalSales ts ON od.o_orderkey = ts.l_orderkey
LEFT JOIN SupplierSales ss ON ss.s_name LIKE CONCAT('%', LEFT(od.c_name, 3), '%')
WHERE od.rn = 1
ORDER BY od.o_totalprice DESC, total_sales DESC;
