WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
CustomerSales AS (
    SELECT c.c_custkey, 
           c.c_name, 
           SUM(o.o_totalprice) AS total_sales,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey
),
PartSales AS (
    SELECT p.p_partkey,
           p.p_name,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY p.p_partkey
),
FinalReport AS (
    SELECT c.c_custkey,
           c.c_name,
           cs.total_sales,
           COALESCE(ps.total_revenue, 0) AS total_revenue,
           COALESCE(cs.total_sales, 0) - COALESCE(ps.total_revenue, 0) AS profit
    FROM CustomerSales cs
    FULL OUTER JOIN PartSales ps ON cs.c_custkey = ps.p_partkey
    JOIN region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = cs.c_custkey)
    WHERE profit IS NOT NULL AND profit > 0
),
RankedSales AS (
    SELECT f.*, 
           RANK() OVER (ORDER BY profit DESC) AS sales_rank
    FROM FinalReport f
)
SELECT r.r_name, 
       COUNT(*) AS high_profit_count,
       AVG(f.profit) AS average_profit
FROM RankedSales f
JOIN nation n ON f.c_custkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE f.sales_rank <= 10
GROUP BY r.r_name
HAVING AVG(f.profit) > 5000
ORDER BY high_profit_count DESC;
