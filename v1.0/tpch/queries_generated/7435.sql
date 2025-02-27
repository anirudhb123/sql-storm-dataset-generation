WITH TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY TotalSupplyCost DESC
    LIMIT 10
), RecentOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_name, c.c_nationkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE_SUB(CURRENT_DATE, INTERVAL 1 YEAR)
), ProductSummary AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_quantity) AS TotalQuantity, SUM(l.l_extendedprice) AS TotalRevenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING TotalRevenue > 10000
), NationSummary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT c.c_custkey) AS UniqueCustomers
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT ts.s_name AS SupplierName, 
       ro.o_orderkey AS OrderKey, 
       ro.o_totalprice AS OrderTotalPrice, 
       ps.p_name AS ProductName, 
       ps.TotalQuantity, 
       ps.TotalRevenue, 
       ns.n_name AS NationName, 
       ns.UniqueCustomers
FROM TopSuppliers ts
JOIN RecentOrders ro ON ts.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p))
JOIN ProductSummary ps ON ps.TotalRevenue > 10000
JOIN NationSummary ns ON ns.UniqueCustomers > 5
WHERE ro.o_totalprice > 5000
ORDER BY ts.TotalSupplyCost DESC, ro.o_orderdate DESC;
