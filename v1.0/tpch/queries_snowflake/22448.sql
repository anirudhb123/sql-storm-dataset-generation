
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT sp.s_suppkey, sp.s_name, sp.s_nationkey, sh.level + 1
    FROM supplier sp
    JOIN SupplierHierarchy sh ON sp.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
NationParts AS (
    SELECT n.n_nationkey, n.n_name, LISTAGG(DISTINCT p.p_name, ', ') AS parts
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY n.n_nationkey, n.n_name
),
SalesData AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
),
RankedSales AS (
    SELECT sd.o_orderkey, 
           sd.total_sales, 
           sd.o_orderdate,
           RANK() OVER (PARTITION BY DATE_TRUNC('month', sd.o_orderdate) ORDER BY sd.total_sales DESC) AS sales_rank
    FROM SalesData sd
)
SELECT r.r_name,
       np.parts,
       COALESCE(RANK() OVER (ORDER BY SUM(sd.total_sales) DESC), 0) AS region_rank,
       SUM(sd.total_sales) AS total_sales_per_region,
       CASE WHEN SUM(sd.total_sales) IS NULL THEN 'No sales'
            WHEN AVG(sd.total_sales) > 1000 THEN 'High performers'
            ELSE 'Low performers' END AS performance_category
FROM NationParts np
JOIN region r ON np.n_nationkey = r.r_regionkey
LEFT JOIN RankedSales sd ON r.r_regionkey = sd.o_orderkey
WHERE r.r_name NOT LIKE '%test%' AND np.parts IS NOT NULL
GROUP BY r.r_name, np.parts
HAVING SUM(sd.total_sales) > (SELECT AVG(total_sales) FROM RankedSales)
ORDER BY region_rank DESC, total_sales_per_region DESC
LIMIT 10;
