WITH RECURSIVE SupplierCTE AS (
    SELECT s_suppkey, s_name, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, level + 1
    FROM supplier s
    JOIN SupplierCTE cte ON s.s_suppkey <> cte.s_suppkey AND s.s_acctbal > cte.s_acctbal
    WHERE level < 5
),
RankedLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, l.l_quantity, l.l_extendedprice,
           RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS item_rank
    FROM lineitem l
    WHERE l.l_discount BETWEEN 0.05 AND 0.20
),
AvgSupplierCost AS (
    SELECT ps_suppkey,
           AVG(ps_supplycost) AS avg_cost
    FROM partsupp
    GROUP BY ps_suppkey
)
SELECT r.r_name, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       MAX(s.s_acctbal) AS max_supplier_balance,
       COALESCE(AVG(asc.avg_cost), 0) AS avg_part_cost
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN orders o ON s.s_suppkey = o.o_custkey
JOIN RankedLineItems l ON o.o_orderkey = l.l_orderkey
LEFT JOIN AvgSupplierCost asc ON s.s_suppkey = asc.ps_suppkey
WHERE s.s_acctbal IS NOT NULL
GROUP BY r.r_name
HAVING total_sales > 10000
ORDER BY total_sales DESC
LIMIT 10;
