WITH RECURSIVE CTE_Supplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal >= 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, cte.level + 1
    FROM supplier s
    JOIN CTE_Supplier cte ON s.s_acctbal >= cte.s_acctbal * 0.75
),
Snapshot AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(COALESCE(l.l_discount, 0)) AS total_discount,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS total_nations,
    SUM(ps.ps_availqty) AS total_availqty,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    p_total.total_discount,
    o_stats.revenue
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN partsupp ps ON n.n_nationkey = ps.ps_suppkey
JOIN CTE_Supplier s ON n.n_nationkey = s.s_suppkey
JOIN Snapshot p_total ON s.s_suppkey = p_total.p_partkey
LEFT JOIN OrderStats o_stats ON o_stats.o_orderdate = current_date
WHERE p_total.total_discount IS NOT NULL
GROUP BY r.r_name, p_total.total_discount, o_stats.revenue
HAVING SUM(ps.ps_availqty) > 1000
ORDER BY avg_supplier_balance DESC
LIMIT 10;
