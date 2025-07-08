WITH RECURSIVE SupplierHierarchy(s_suppkey, s_name, s_acctbal, r_level) AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1
    FROM supplier s
    INNER JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_name LIKE 'A%' 
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, rh.r_level + 1
    FROM supplier s
    JOIN SupplierHierarchy rh ON s.s_nationkey = rh.s_suppkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
),
PartStats AS (
    SELECT p.p_partkey, p.p_size, SUM(ps.ps_supplycost) AS total_supplycost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_size
    HAVING COUNT(DISTINCT ps.ps_suppkey) > 2 
),
OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
           COUNT(l.l_linenumber) AS line_count,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('F', 'O')
    GROUP BY o.o_orderkey
)
SELECT 
    rh.s_name AS supplier_name,
    COUNT(DISTINCT os.o_orderkey) AS total_orders,
    SUM(DISTINCT ps.total_supplycost) AS total_supplycost,
    CASE WHEN MAX(ps.p_size) IS NULL THEN 'No parts' ELSE CAST(MAX(ps.p_size) AS VARCHAR) END AS max_part_size,
    MAX(CASE WHEN os.line_count > 10 THEN 'High' ELSE 'Low' END) AS order_line_status,
    NULLIF(MIN(os.net_revenue), 0) AS min_net_revenue,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY os.net_revenue) AS median_revenue
FROM SupplierHierarchy rh
LEFT JOIN OrderStats os ON rh.s_suppkey = os.o_orderkey
LEFT JOIN PartStats ps ON rh.s_suppkey = ps.p_partkey
GROUP BY rh.s_name
HAVING COUNT(*) < (SELECT COUNT(DISTINCT s.c_name) FROM customer s WHERE s.c_acctbal < 5000)
ORDER BY total_orders DESC NULLS LAST
LIMIT 10;