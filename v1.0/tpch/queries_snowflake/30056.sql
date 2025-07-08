
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
OrdDetails AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_orderkey) AS line_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
), 
NationSummary AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS suppliers_count,
        MAX(s.s_acctbal) AS max_balance,
        AVG(s.s_acctbal) AS avg_balance
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT 
    ns.nation_name,
    ns.suppliers_count,
    ns.max_balance,
    ns.avg_balance,
    od.total_price,
    COALESCE(od.line_count, 0) AS total_lines,
    CASE 
        WHEN od.order_rank IS NULL THEN 'No Orders'
        WHEN od.line_count > 5 THEN 'High Activity'
        ELSE 'Standard'
    END AS order_activity
FROM NationSummary ns
LEFT JOIN OrdDetails od ON ns.suppliers_count = od.line_count
JOIN region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name = 'USA')
ORDER BY ns.nation_name, od.total_price DESC NULLS LAST;
