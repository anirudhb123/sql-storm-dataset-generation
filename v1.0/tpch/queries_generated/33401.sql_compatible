
WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sc.level + 1
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN SupplyChain sc ON ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 20 AND p.p_retailprice IS NOT NULL)
    WHERE s.s_acctbal < sc.s_acctbal 
),
HighPriceOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_mktsegment
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2) 
),
AggregateInfo AS (
    SELECT np.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
           np.n_nationkey
    FROM nation np
    LEFT JOIN supplier s ON np.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY np.n_name, np.n_nationkey
),
FinalAnalysis AS (
    SELECT n.n_name AS nation_name, ai.supplier_count, ai.total_revenue,
           DENSE_RANK() OVER (ORDER BY ai.total_revenue DESC) AS revenue_rank
    FROM AggregateInfo ai
    JOIN nation n ON ai.n_nationkey = n.n_nationkey
)
SELECT 
    f.nation_name,
    f.supplier_count,
    f.total_revenue,
    COALESCE(hpo.o_totalprice, 0) AS high_price_order_total,
    CASE 
        WHEN f.total_revenue > 1000000 THEN 'High Revenue'
        WHEN f.total_revenue BETWEEN 500000 AND 1000000 THEN 'Medium Revenue'
        ELSE 'Low Revenue' 
    END AS revenue_category
FROM FinalAnalysis f
LEFT JOIN HighPriceOrders hpo ON f.nation_name = hpo.c_mktsegment 
WHERE f.revenue_rank <= 5;
