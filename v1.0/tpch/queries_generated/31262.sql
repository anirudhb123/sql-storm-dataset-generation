WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal <= 10000 AND sh.level < 5
),
OrderStats AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS num_parts,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
MaxOrderRevenue AS (
    SELECT
        o.o_custkey,
        MAX(os.total_revenue) AS max_revenue
    FROM orders o
    JOIN OrderStats os ON o.o_orderkey = os.o_orderkey
    GROUP BY o.o_custkey
)
SELECT
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    MAX(o.total_revenue) AS max_order_revenue,
    NULLIF(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END), 0) AS total_returned_quantity,
    CASE 
        WHEN r.r_name IS NULL THEN 'Unknown Region'
        ELSE r.r_name 
    END AS region_name
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN OrderStats o ON o.o_orderkey = ps.ps_partkey
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
AND EXISTS (
    SELECT 1
    FROM SupplierHierarchy sh
    WHERE sh.s_nationkey = s.s_nationkey
)
GROUP BY p.p_name, r.r_name
HAVING COUNT(DISTINCT ps.ps_suppkey) > 5
ORDER BY avg_supply_cost DESC, total_returned_quantity ASC;
