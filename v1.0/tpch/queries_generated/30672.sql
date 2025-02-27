WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal,
           1 AS level
    FROM supplier
    WHERE s_acctbal > 5000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal AND sh.level < 5
), 
SalesData AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        l.l_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31' AND l.l_returnflag = 'N'
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
)
SELECT 
    c.c_custkey, 
    c.c_name AS customer_name,
    COALESCE(SH.s_name, 'No Supplier') AS supplier_name,
    COALESCE(SD.cumulative_sales, 0) AS total_sales,
    TS.total_supply_cost
FROM customer c
LEFT JOIN SupplierHierarchy SH ON c.c_nationkey = SH.s_nationkey
LEFT JOIN SalesData SD ON c.c_custkey = SD.c_custkey
LEFT JOIN TopSuppliers TS ON SH.s_suppkey = TS.s_suppkey
ORDER BY total_sales DESC, c.c_name ASC;
