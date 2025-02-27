WITH ranked_orders AS (
    SELECT 
        o.o_orderkey, 
        c.c_name, 
        o.o_totalprice, 
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
), 
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_availqty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    SUM(CASE 
            WHEN lo.l_returnflag = 'R' THEN lo.l_extendedprice * (1 - lo.l_discount)
            ELSE 0 
        END) AS total_returns,
    AVG(s.total_supplycost) AS avg_supplycost,
    MAX(o.o_totalprice) AS max_order_value
FROM ranked_orders o
FULL OUTER JOIN nation n ON n.n_nationkey IN (SELECT DISTINCT c.c_nationkey FROM customer c WHERE c.c_custkey = o.o_custkey)
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN lineitem lo ON o.o_orderkey = lo.l_orderkey
JOIN supplier_summary s ON s.s_suppkey = lo.l_suppkey
WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-12-31'
GROUP BY r.r_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY nation_count DESC, max_order_value DESC;
