WITH CTE_Supplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.n_nationkey = n.n_nationkey
    WHERE n.n_name LIKE '%%'
), 
CTE_Part AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           CASE 
               WHEN p.p_size IS NULL THEN 'Unknown Size'
               ELSE CAST(p.p_size AS VARCHAR) || ' Size'
           END AS size_info
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
), 
CTE_Order AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderstatus, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderstatus
)
SELECT r.r_name,
       COUNT(DISTINCT s.s_suppkey) AS supplier_count,
       COALESCE(SUM(p.p_retailprice), 0) AS total_part_retail,
       AVG(o.total_sales) AS avg_order_sales,
       STRING_AGG(CASE WHEN s.rn <= 5 THEN s.s_name END, ', ') AS top_suppliers
FROM region r
LEFT JOIN CTE_Supplier s ON r.r_regionkey = s.s_suppkey
LEFT JOIN CTE_Part p ON p.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_availqty > 10
)
FULL OUTER JOIN CTE_Order o ON o.o_orderkey = (
    SELECT MAX(o2.o_orderkey) 
    FROM CTE_Order o2 
    WHERE o2.o_totalprice > 1000
) OR p.p_partkey IS NULL
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name
HAVING COUNT(DISTINCT s.s_suppkey) > 0 OR AVG(o.total_sales) > 5000
ORDER BY r.r_name;
