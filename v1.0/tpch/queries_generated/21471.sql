WITH RECURSIVE CTE_Supplier AS (
    SELECT s_suppkey, s_name, s_acctbal
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    INNER JOIN CTE_Supplier cte ON s.s_suppkey = cte.s_suppkey + 1
),
CTE_Part AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           RANK() OVER (PARTITION BY p.p_size ORDER BY p.p_retailprice DESC) AS rnk
    FROM part p
    WHERE p.p_retailprice > 100 AND p.p_size % 2 = 0
),
Total_Orders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT p.p_name, p.p_retailprice, 
       COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
       COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
       COALESCE(SUM(to.total_revenue), 0) AS total_revenue,
       CASE WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) IS NULL THEN 'no revenue' 
            ELSE 'revenue present' END AS revenue_status
FROM CTE_Part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN CTE_Supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN Total_Orders to ON l.l_orderkey = to.o_orderkey
GROUP BY p.p_name, p.p_retailprice, s.s_name
HAVING (SUM(l.l_quantity) > 10 OR SUM(l.l_quantity) IS NULL)
   AND p.rnk <= 5
ORDER BY p.p_retailprice DESC, supplier_name
LIMIT 10 OFFSET 0;
