WITH supplier_totals AS (
    SELECT 
        s.s_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        MIN(s.s_acctbal) AS min_acctbal
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
customer_summary AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey
),
top_nations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey
    HAVING COUNT(DISTINCT s.s_suppkey) > 5
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank,
    STUFF((SELECT ',' + DISTINCT s.s_name
           FROM supplier s
           JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
           WHERE ps.ps_partkey = p.p_partkey
           FOR XML PATH('')), 1, 1, '') AS suppliers_list,
    (SELECT MAX(total_cost) FROM supplier_totals) AS max_cost,
    CASE 
        WHEN total_spent IS NULL THEN 'No Orders'
        ELSE 'Orders Present'
    END AS order_status
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN customer_summary cs ON l.l_orderkey IN 
    (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey)
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, cs.total_spent
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 10 OR SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(total_spent) FROM customer_summary)
ORDER BY p.p_partkey, revenue_rank
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
