WITH RECURSIVE nested_orders AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, no.level + 1
    FROM orders o
    JOIN nested_orders no ON o.o_custkey = no.o_custkey
    WHERE no.level < 5 AND o.o_orderdate > DATEADD(DAY, -30, no.o_orderdate)
),
order_summary AS (
    SELECT 
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) as spending_rank
    FROM customer c
    JOIN nested_orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_name
),
supplier_part AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
top_nations AS (
    SELECT 
        n.n_nationkey,
        RANK() OVER (ORDER BY COUNT(s.s_nationkey) DESC) as nation_rank
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey
    HAVING COUNT(s.s_nationkey) > 5
)
SELECT 
    os.c_name,
    os.total_spent,
    os.order_count,
    os.avg_order_value,
    sp.part_count,
    sp.total_supplycost,
    tn.nation_rank
FROM order_summary os
INNER JOIN supplier_part sp ON os.spending_rank < 10 AND sp.part_count > 3
LEFT JOIN top_nations tn ON sp.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_availqty IS NULL)
WHERE os.avg_order_value BETWEEN 100 AND 1000
ORDER BY os.total_spent DESC, tn.nation_rank ASC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
