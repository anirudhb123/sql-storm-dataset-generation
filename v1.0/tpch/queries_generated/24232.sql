WITH RECURSIVE CTE_Supplier AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
        AND s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name LIKE 'A%')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
    FROM supplier s
    INNER JOIN CTE_Supplier cte ON s.s_nationkey = cte.s_nationkey
    WHERE s.s_acctbal > cte.s_acctbal * 0.9
),
CTE_Parts AS (
    SELECT p.p_partkey, SUM(ps.ps_availqty) AS total_availqty, AVG(p.p_retailprice) AS avg_retailprice
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
CTE_Orders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales, o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
CTE_Customer AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_mktsegment IN ('BUILDING', 'FURNITURE')
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 2
)
SELECT 
    c.c_name, 
    COALESCE(cte.total_availqty, 0) AS total_availqty,
    COALESCE(cte.avg_retailprice, 0) AS avg_retailprice,
    cte_orders.net_sales,
    n.n_name,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY c.c_name) AS row_num
FROM CTE_Customer c
JOIN CTE_Supplier s ON s.s_suppkey = (SELECT MAX(supp.s_suppkey) FROM CTE_Supplier supp)
LEFT JOIN CTE_Parts cte ON cte.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_supplycost > (SELECT AVG(ps2.ps_supplycost) FROM partsupp ps2)
)
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN CTE_Orders cte_orders ON cte_orders.net_sales > 10000
WHERE n.r_regionkey IS NULL OR n.r_regionkey = 1
ORDER BY row_num DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
