WITH RECURSIVE CTE_Suppliers AS (
    SELECT s_suppkey, s_name, s_address, s_nationkey, s_acctbal,
           CAST(s_name AS VARCHAR(100)) AS full_info,
           ROW_NUMBER() OVER (ORDER BY s_acctbal DESC) AS ranking
    FROM supplier
    WHERE s_acctbal IS NOT NULL AND s_acctbal > 0
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal,
           CTE_Suppliers.full_info || ', ' || s.s_name,
           ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC)
    FROM supplier s
    JOIN CTE_Suppliers ON s.s_suppkey = CTE_Suppliers.s_suppkey + 1
    WHERE CTE_Suppliers.ranking < 5
),
Highlighted_Parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           CASE
               WHEN p.p_size IS NULL THEN 'Unknown Size'
               WHEN p.p_size < 1 THEN 'Miniature'
               WHEN p.p_size BETWEEN 1 AND 10 THEN 'Standard'
               ELSE 'Large'
           END AS size_category
    FROM part p
    WHERE p.p_retailprice >= (
        SELECT AVG(p2.p_retailprice)
        FROM part p2
        WHERE p2.p_retailprice IS NOT NULL
    )
),
Order_Summary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           RANK() OVER (PARTITION BY DATE_TRUNC('month', o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS monthly_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus != 'F'
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT COALESCE(s.s_name, 'No Supplier') AS supplier_name,
       COALESCE(p.p_name, 'No Part') AS part_name,
       COALESCE(os.total_revenue, 0) AS total_revenue,
       sp.p_type, sp.size_category
FROM supplier s
FULL OUTER JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
FULL OUTER JOIN Highlighted_Parts p ON ps.ps_partkey = p.p_partkey
LEFT JOIN Order_Summary os ON os.o_orderkey = ps.ps_partkey
LEFT JOIN (SELECT DISTINCT ps_partkey, p_type
            FROM partsupp ps
            JOIN part p ON ps.ps_partkey = p.p_partkey
            WHERE p.p_retailprice IS NOT NULL) sp ON sp.ps_partkey = p.p_partkey
WHERE (s.s_nationkey IS NULL OR s.s_nationkey IN 
       (SELECT n.n_nationkey FROM nation n WHERE n.n_comment IS NOT NULL))
    AND (p.p_size IS NULL OR p.p_size > 0)
ORDER BY supplier_name, part_name DESC
FETCH FIRST 50 ROWS ONLY
WITH TIMEOUT FOR 30;
