WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > 5000
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_custkey
    WHERE c.c_acctbal > 5000
), 
AggregatedOrders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2022-01-01' 
    GROUP BY o.o_orderkey, o.o_custkey
), 
SupplierPartCounts AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
), 
NationStatistics AS (
    SELECT n.n_name, COUNT(DISTINCT c.c_custkey) AS customer_count,
           COALESCE(SUM(s.s_acctbal), 0) AS total_supplier_balance
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT DISTINCT
    p.p_name, 
    ph.total_revenue AS order_revenue, 
    ns.customer_count AS nation_customers, 
    ns.total_supplier_balance,
    CONCAT('Supplier Count: ', CAST(spc.supplier_count AS VARCHAR)) AS supplier_info,
    CASE 
        WHEN ph.total_revenue > 20000 THEN 'High Revenue'
        WHEN ph.total_revenue BETWEEN 10000 AND 20000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM part p
JOIN AggregatedOrders ph ON p.p_partkey = ph.o_custkey
JOIN SupplierPartCounts spc ON spc.ps_partkey = p.p_partkey
JOIN NationStatistics ns ON ns.n_name = (SELECT n_name FROM nation WHERE n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = ph.o_custkey))
WHERE EXISTS (
    SELECT 1 
    FROM CustomerHierarchy ch
    WHERE ch.c_custkey = ph.o_custkey AND ch.level = 1
)
ORDER BY order_revenue DESC, nation_customers DESC;
