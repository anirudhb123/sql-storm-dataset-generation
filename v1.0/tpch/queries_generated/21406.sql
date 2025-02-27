WITH RECURSIVE CTE1 AS (
    SELECT n.n_name, s.s_acctbal, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY n.n_name, s.s_acctbal
),
CTE2 AS (
    SELECT c.c_name, o.o_orderkey, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn,
           CASE 
               WHEN o.o_orderstatus = 'F' THEN 'Completed'
               ELSE 'Pending'
           END AS order_status,
           COALESCE(cte1.total_sales, 0) AS nation_sales
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN CTE1 cte1 ON c.c_nationkey = (
        SELECT n.n_nationkey 
        FROM nation n
        WHERE n.n_name = c.c_comment
    )
    WHERE c.c_acctbal > 
        (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_mktsegment = c.c_mktsegment)
),
FilteredOrders AS (
    SELECT cte2.c_name, cte2.o_orderkey, cte2.o_totalprice, cte2.order_status, cte2.nation_sales
    FROM CTE2 cte2
    WHERE cte2.rn = 1 AND cte2.nation_sales > 1000
),
Final AS (
    SELECT f.c_name, f.o_orderkey, f.o_totalprice, f.order_status,
           CASE 
               WHEN f.o_totalprice IS NOT NULL THEN f.o_totalprice * 0.05
               ELSE NULL
           END AS potential_discount
    FROM FilteredOrders f
    WHERE f.nation_sales IS NOT NULL
)
SELECT f.c_name, f.o_orderkey, f.o_totalprice, f.order_status, f.potential_discount,
       ROW_NUMBER() OVER (ORDER BY f.o_totalprice DESC) AS sales_rank
FROM Final f
WHERE f.potential_discount IS NOT NULL
UNION ALL
SELECT 'Total Sales', NULL, SUM(f.o_totalprice), 'Aggregate', SUM(f.potential_discount)
FROM Final f
WHERE f.potential_discount IS NOT NULL
GROUP BY f.p_name
ORDER BY 6 DESC NULLS LAST;
