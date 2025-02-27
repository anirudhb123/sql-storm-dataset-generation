WITH RECURSIVE price_trend AS (
    SELECT 
        ps.partkey,
        ps.suppkey,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY ps.partkey ORDER BY ps.ps_supplycost DESC) AS rank
    FROM partsupp ps
    WHERE ps.ps_supplycost IS NOT NULL
),
avg_supplier_cost AS (
    SELECT 
        ps.partkey,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.partkey
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('F', 'O')
    GROUP BY c.c_custkey
)

SELECT 
    p.p_name,
    COALESCE(NULLIF(r.r_name, ''), 'Unknown Region') AS region_name,
    COUNT(DISTINCT c.c_custkey) AS customers_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(ps.ps_supplycost) AS avg_cost,
    MAX(pr.ps_supplycost) AS max_supply_cost,
    CASE
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
LEFT JOIN supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN price_trend pr ON p.p_partkey = pr.partkey
GROUP BY p.p_name, r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 5 AND AVG(ps.ps_supplycost) < 50
ORDER BY total_revenue DESC, p.p_name
LIMIT 10;
