WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal > 1000 AND sh.level < 5
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS item_count,
        AVG(l.l_quantity) AS avg_quantity
    FROM lineitem l
    GROUP BY l.l_orderkey
),
NationRevenues AS (
    SELECT 
        n.n_key,
        SUM(l.total_revenue) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY n.n_nationkey
)
SELECT 
    RANK() OVER (ORDER BY nr.total_revenue DESC) AS revenue_rank,
    n.r_name,
    n.n_nationkey,
    nr.total_revenue,
    nr.order_count,
    COALESCE(sh.level, 0) AS supplier_level
FROM region n
LEFT JOIN NationRevenues nr ON n.r_regionkey = nr.n_nationkey
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = nr.n_nationkey
WHERE nr.total_revenue IS NOT NULL
ORDER BY revenue_rank;

