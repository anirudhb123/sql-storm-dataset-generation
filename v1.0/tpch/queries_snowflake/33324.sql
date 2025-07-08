
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS Level
    FROM supplier s
    WHERE s.s_acctbal > 50000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_acctbal > sh.s_acctbal
)

SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS Total_Customers,
    SUM(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE 0 END) AS Total_Finished_Orders,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS Avg_Adjusted_Price,
    MAX(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity END) AS Max_Returned_Quantity,
    LISTAGG(DISTINCT p.p_comment, '; ') AS Comments,
    SUM(COALESCE(ps.ps_availqty, 0) * COALESCE(ps.ps_supplycost, 0)) AS Total_Supply_Cost
FROM nation n
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN SupplierHierarchy sh ON p.p_brand = (CASE 
                                                  WHEN sh.Level = 1 THEN 'BrandA'
                                                  ELSE p.p_brand
                                                END)
WHERE n.n_name IS NOT NULL
GROUP BY n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 10
ORDER BY Total_Finished_Orders DESC
LIMIT 5;
