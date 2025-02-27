WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 0 AS level
    FROM customer c
    WHERE c.c_acctbal > 10000
    UNION ALL
    SELECT ch.c_custkey, ch.c_name, ch.c_acctbal, ch.level + 1
    FROM CustomerHierarchy ch
    JOIN orders o ON ch.c_custkey = o.o_custkey
    WHERE o.o_totalprice > 5000
),
TotalSales AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
),
SupplierPartDetails AS (
    SELECT p.p_partkey, p.p_name, s.s_suppkey, s.s_acctbal, 
           (SELECT MAX(ps.ps_supplycost) 
            FROM partsupp ps 
            WHERE ps.ps_partkey = p.p_partkey) AS max_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
AggregatedRegionSales AS (
    SELECT n.n_regionkey, r.r_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS region_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_regionkey, r.r_name
)
SELECT rh.level, p.p_name, p.p_retailprice, 
       COALESCE(ts.total_sales, 0) AS customer_total_sales, 
       COALESCE(rs.region_sales, 0) AS region_total_sales,
       spd.max_supplycost
FROM CustomerHierarchy rh
LEFT JOIN TotalSales ts ON rh.c_custkey = ts.o_custkey
JOIN SupplierPartDetails spd ON rh.level = 0
LEFT JOIN AggregatedRegionSales rs ON spd.s_suppkey = rs.r_regionkey
WHERE (customer_total_sales > 10000 OR region_total_sales > 20000)
ORDER BY rh.level DESC, p.p_retailprice DESC
LIMIT 50;
