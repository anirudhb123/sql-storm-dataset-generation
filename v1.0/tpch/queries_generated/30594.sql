WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost ASC) AS row_num
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
), RankedSuppliers AS (
    SELECT s.s_nationkey, SUM(s.ps_supplycost * s.ps_availqty) AS total_cost
    FROM SupplyChain s
    WHERE s.row_num <= 5
    GROUP BY s.s_nationkey
), NationSummary AS (
    SELECT n.n_name, n.n_regionkey, COALESCE(rs.total_cost, 0) AS total_cost
    FROM nation n
    LEFT JOIN RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey
), RegionSummaries AS (
    SELECT r.r_name, SUM(ns.total_cost) AS region_cost
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN NationSummary ns ON n.n_nationkey = ns.n_nationkey
    GROUP BY r.r_name
)
SELECT r.r_name AS region_name, 
       r.region_cost AS total_region_cost, 
       CASE 
           WHEN r.region_cost > 100000 THEN 'High'
           WHEN r.region_cost BETWEEN 50000 AND 100000 THEN 'Medium'
           ELSE 'Low'
       END AS cost_category
FROM RegionSummaries r
ORDER BY r.region_cost DESC
LIMIT 10;

SELECT DISTINCT c.c_name, 
                CASE 
                    WHEN o.o_orderpriority = '1-URGENT' THEN 'High Priority'
                    ELSE 'Normal Priority'
                END AS order_priority,
                SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
WHERE l.l_returnflag = 'N'
AND c.c_acctbal > (
    SELECT AVG(c2.c_acctbal) 
    FROM customer c2 
    WHERE c2.c_nationkey = c.c_nationkey
)
GROUP BY c.c_name, o.o_orderpriority
ORDER BY total_value DESC;
