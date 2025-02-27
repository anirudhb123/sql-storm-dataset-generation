WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
CustomerSegment AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spending,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    ps.ps_supplycost,
    COALESCE(n.n_name, 'Unknown') AS nation,
    SUM(ps.ps_availqty) AS total_available,
    MAX(c.total_spending) AS max_customer_spending,
    COUNT(DISTINCT sh.s_nationkey) AS supplier_count,
    CASE 
        WHEN SUM(l.l_quantity) > 100 THEN 'High Demand'
        WHEN SUM(l.l_quantity) BETWEEN 50 AND 100 THEN 'Moderate Demand'
        ELSE 'Low Demand'
    END AS demand_level
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN OrderStats os ON os.o_orderkey = l.l_orderkey
LEFT JOIN CustomerSegment c ON os.revenue_rank = c.spending_rank
LEFT JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
WHERE p.p_retailprice > 50
GROUP BY p.p_name, ps.ps_supplycost, n.n_name
HAVING COUNT(DISTINCT l.l_orderkey) > 10
ORDER BY demand_level DESC, total_available DESC;
