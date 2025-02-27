WITH RECURSIVE x AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_orderdate
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000.00
    UNION ALL
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) * 1.05 AS revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_returnflag = 'R'
    GROUP BY o.o_orderkey, o.o_orderdate
),
combined AS (
    SELECT 
        r.r_regionkey,
        n.n_nationkey,
        s.s_suppkey,
        COUNT(DISTINCT c.c_custkey) AS cust_count,
        SUM(COALESCE(ps.ps_supplycost * ps.ps_availqty, 0)) AS total_supply_cost,
        MAX(CASE WHEN (n.n_name LIKE 'A%') THEN s.s_acctbal END) AS max_acctbal_A,
        COUNT(CASE WHEN s.s_comment LIKE '%special%' THEN 1 END) AS special_comment_count
    FROM nation n
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    FULL OUTER JOIN customer c ON s.s_nationkey = c.c_nationkey
    GROUP BY r.r_regionkey, n.n_nationkey, s.s_suppkey
)
SELECT 
    c.r_regionkey,
    c.n_nationkey,
    COALESCE(MAX(d.revenue), 0) AS total_revenue,
    d.o_orderdate,
    c.cust_count,
    c.total_supply_cost,
    c.max_acctbal_A,
    c.special_comment_count,
    ROW_NUMBER() OVER (PARTITION BY c.r_regionkey ORDER BY c.total_supply_cost DESC) AS rank
FROM combined c
LEFT JOIN x d ON c.cust_count = d.o_orderkey
WHERE c.total_supply_cost IS NOT NULL AND c.cust_count > 0
ORDER BY c.r_regionkey, rank
LIMIT 100;
