WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'F'
    UNION ALL
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_custkey = oh.o_orderkey)
    WHERE o.o_orderstatus = 'F' AND oh.level < 5
),
SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueParts AS (
    SELECT p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY p.p_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
),
FinalResults AS (
    SELECT oh.o_orderkey, oh.o_orderdate, oh.o_totalprice, si.s_name, hvp.p_name
    FROM OrderHierarchy oh
    LEFT JOIN SupplierInfo si ON si.rn <= 3 
    LEFT JOIN HighValueParts hvp ON hvp.total_sales > 50000
)
SELECT COALESCE(oh.o_orderkey, 0) AS OrderKey,
       COALESCE(oh.o_orderdate, '1900-01-01') AS OrderDate,
       COALESCE(oh.o_totalprice, 0.00) AS TotalPrice,
       COALESCE(si.s_name, 'Unknown Supplier') AS Supplier,
       COALESCE(hvp.p_name, 'Unknown Part') AS PartName
FROM FinalResults
ORDER BY oh.o_orderdate DESC, si.s_name, hvp.p_name;
