WITH RECURSIVE order_summary AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY o.o_orderkey, c.c_name
), 
costs AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT 
    os.o_orderkey,
    os.c_name,
    os.total_revenue,
    COALESCE(su.s_name, 'No Supplier') AS supplier_name,
    c.total_supply_cost,
    CASE 
        WHEN os.total_revenue > (SELECT AVG(total_revenue) FROM order_summary) THEN 'Above Average'
        ELSE 'Below Average' 
    END AS revenue_status
FROM order_summary os
LEFT JOIN supplier_info su ON os.o_orderkey = su.supplied_parts_count
LEFT JOIN costs c ON os.o_orderkey = (SELECT MIN(o.o_orderkey) FROM orders o WHERE o.o_orderkey >= os.o_orderkey)
ORDER BY os.total_revenue DESC, os.o_orderkey
FETCH FIRST 10 ROWS ONLY;

SELECT 
    c.c_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
WHERE c.c_acctbal IS NOT NULL 
GROUP BY c.c_custkey, c.c_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > (
    SELECT AVG(total_revenue) FROM order_summary
)
INTERSECT
SELECT 
    c.c_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
WHERE c.c_acctbal IS NULL
GROUP BY c.c_custkey, c.c_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) < (
    SELECT AVG(total_revenue) FROM order_summary
);
