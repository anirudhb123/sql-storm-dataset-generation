WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, CAST(s_name AS VARCHAR(255)) AS full_hierarchy
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, CONCAT(sh.full_hierarchy, ' -> ', s.s_name)
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal BETWEEN sh.s_acctbal * 0.5 AND sh.s_acctbal * 1.5
),
NationSummary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT c.c_custkey) AS customer_count,
           SUM(o.o_totalprice) AS total_order_value
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_nationkey, n.n_name
),
PartSupplierStats AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
RankedLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_extendedprice,
           RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS price_rank
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
),
FinalResults AS (
    SELECT n.n_name, ps.p_name, COUNT(DISTINCT l.l_orderkey) AS order_count,
           SUM(l.l_extendedprice) AS total_revenue,
           COALESCE(SUM(CASE WHEN r.price_rank = 1 THEN l.l_extendedprice END), 0) AS highest_single_sale
    FROM NationSummary n
    JOIN RankedLineItems l ON l.l_orderkey IN (
        SELECT o.o_orderkey FROM orders o WHERE o.o_orderdate >= '2023-01-01'
    )
    JOIN PartSupplierStats ps ON l.l_partkey = ps.p_partkey
    LEFT JOIN RankedLineItems r ON l.l_orderkey = r.l_orderkey
    GROUP BY n.n_name, ps.p_name
)
SELECT *, CASE 
           WHEN order_count > 100 THEN 'High Volume' 
           WHEN order_count <= 10 THEN 'Low Volume' 
           ELSE 'Medium Volume' 
         END AS order_volume_category
FROM FinalResults
WHERE total_revenue IS NOT NULL
ORDER BY total_revenue DESC
LIMIT 10;
