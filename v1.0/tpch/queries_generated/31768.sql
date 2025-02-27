WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_nationkey, s_suppkey, s_name, s_acctbal
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.n_nationkey, s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
),
PartSuppliers AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
OrderStats AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM orders o
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_custkey
),
NationDetails AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    pd.p_partkey, 
    pd.p_name, 
    n.n_name AS nation_name,
    SUM(ls.l_extendedprice * (1 - ls.l_discount)) AS total_revenue,
    AVG(ls.l_quantity) AS avg_quantity,
    COUNT(DISTINCT oi.o_custkey) AS unique_customers,
    (CASE 
        WHEN ps.total_qty IS NULL THEN 0 
        ELSE ps.total_qty 
     END) AS available_quantity,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY total_revenue DESC) AS revenue_rank 
FROM part pd
LEFT JOIN lineitem ls ON pd.p_partkey = ls.l_partkey
LEFT JOIN orders oi ON ls.l_orderkey = oi.o_orderkey
LEFT JOIN PartSuppliers ps ON pd.p_partkey = ps.ps_partkey
INNER JOIN NationDetails n ON n.n_nationkey = (
    SELECT sh.s_nationkey 
    FROM SupplierHierarchy sh 
    WHERE sh.s_suppkey = ls.l_suppkey 
    LIMIT 1
)
WHERE ls.l_shipdate >= CURRENT_DATE - INTERVAL '1 year' 
GROUP BY 
    pd.p_partkey, 
    pd.p_name, 
    n.n_name 
ORDER BY 
    total_revenue DESC 
LIMIT 50;
