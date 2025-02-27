WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 5
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_name, ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'F' AND o.o_totalprice > 1000
),
PartSales AS (
    SELECT p.p_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey
)
SELECT 
    n.n_name AS nation, 
    r.r_name AS region, 
    SH.s_name AS supplier_name, 
    HVO.o_orderkey, 
    HVO.o_totalprice, 
    PS.total_sales, 
    (CASE 
        WHEN PS.total_sales IS NULL THEN 'No sales recorded' 
        ELSE 'Sales recorded' 
    END) AS sales_status
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierHierarchy SH ON n.n_nationkey = SH.s_suppkey
LEFT JOIN HighValueOrders HVO ON HVO.o_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    WHERE o.o_custkey IN (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_acctbal > 5000
    )
)
LEFT JOIN PartSales PS ON PS.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_availqty > 0
)
WHERE n.n_name LIKE 'A%'
ORDER BY r.r_name, n.n_name, HVO.o_totalprice DESC;
