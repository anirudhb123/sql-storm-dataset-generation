WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS depth
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT sh.s_suppkey, s.s_name, s.s_acctbal, depth + 1
    FROM SupplierHierarchy sh
    JOIN supplier s ON sh.s_suppkey = s.s_suppkey
    WHERE s.s_acctbal > sh.s_acctbal AND sh.depth < 5
),
PartStats AS (
    SELECT p.p_partkey, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
LineItemSales AS (
    SELECT l.l_partkey,
           COUNT(*) AS sales_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY l.l_partkey
),
RankedSales AS (
    SELECT l.*, 
           RANK() OVER (PARTITION BY l.l_partkey ORDER BY l.sales_count DESC) AS rnk
    FROM LineItemSales l
),
FilteredSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           CASE 
               WHEN s.s_acctbal IS NULL THEN 'Unknown' 
               ELSE 'Known' 
           END AS acct_status
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
)
SELECT p.p_partkey, p.p_name, ps.total_available, ps.avg_supply_cost, 
       COUNT(DISTINCT cs.c_custkey) AS customer_count,
       string_agg(DISTINCT fs.s_name || ' (' || fs.acct_status || ')', ', ') AS suppliers_info
FROM part p
LEFT JOIN PartStats ps ON p.p_partkey = ps.p_partkey
LEFT JOIN orders o ON o.o_orderkey IN (SELECT l.l_orderkey
                                         FROM lineitem l
                                         WHERE l.l_partkey = p.p_partkey)
LEFT JOIN customer cs ON o.o_custkey = cs.c_custkey
LEFT JOIN FilteredSuppliers fs ON fs.s_suppkey IN (SELECT ps.ps_suppkey
                                                    FROM partsupp ps
                                                    WHERE ps.ps_partkey = p.p_partkey)
WHERE ps.total_available IS NOT NULL 
AND (p.p_size BETWEEN 1 AND 50 OR (p.p_size IS NULL))
AND (SELECT COUNT(*) FROM SupplierHierarchy sh WHERE sh.s_acctbal < fs.s_acctbal) = 0
GROUP BY p.p_partkey, p.p_name, ps.total_available, ps.avg_supply_cost
HAVING COUNT(DISTINCT cs.c_custkey) > 5
ORDER BY total_available DESC NULLS LAST, avg_supply_cost ASC;
