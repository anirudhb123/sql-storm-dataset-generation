WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_regionkey = 1)
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = (sh.s_suppkey % 25) + 1
    WHERE sh.level < 5
),
TotalLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP BY l.l_orderkey
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_orderdate,
           CASE WHEN o.o_orderstatus = 'O' THEN 'Open' ELSE 'Closed' END AS order_status,
           COALESCE(t.total_revenue, 0) AS revenue,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY COALESCE(t.total_revenue, 0) DESC) AS revenue_rank
    FROM orders o
    LEFT JOIN TotalLineItems t ON o.o_orderkey = t.l_orderkey
    WHERE o.o_orderpriority IN ('HIGH', 'MEDIUM') AND o.o_totalprice > 1000
),
SupplierStats AS (
    SELECT p.p_partkey, p.p_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice >= 10.00)
    GROUP BY p.p_partkey, p.p_name
)
SELECT f.o_orderkey, f.o_orderdate, f.order_status, f.revenue, f.revenue_rank,
       ss.p_partkey, ss.p_name, ss.supplier_count, ss.avg_supplycost,
       CASE 
           WHEN ss.avg_supplycost IS NULL THEN 'No Data' 
           ELSE 'Data Available' 
       END AS supply_cost_status,
       CASE WHEN ss.supplier_count > 5 THEN 'More than 5 Suppliers' ELSE 'Insufficient Suppliers' END AS supplier_classification
FROM FilteredOrders f
LEFT JOIN SupplierStats ss ON f.o_orderkey = (ss.p_partkey % 1000); -- bizarre join condition for demonstration
