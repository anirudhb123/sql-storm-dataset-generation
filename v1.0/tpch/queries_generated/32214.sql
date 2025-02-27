WITH RECURSIVE region_summary AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
),
supplier_summary AS (
    SELECT s.s_nationkey, SUM(s.s_acctbal) AS total_acctbal
    FROM supplier s
    GROUP BY s.s_nationkey
),
order_summary AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) AS total_spent
    FROM orders o
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_custkey
),
line_item_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value,
           ROW_NUMBER() OVER(PARTITION BY l.l_orderkey ORDER BY l.l_orderkey) AS line_rank
    FROM lineitem l
    GROUP BY l.l_orderkey
)

SELECT 
    r.r_name,
    rs.nation_count,
    COALESCE(ss.total_acctbal, 0) AS total_supplier_acctbal,
    COALESCE(os.total_spent, 0) AS total_order_value,
    COUNT(lis.l_orderkey) AS number_of_lines
FROM region_summary rs
LEFT JOIN supplier_summary ss ON ss.s_nationkey IN (
    SELECT n.n_nationkey 
    FROM nation n 
    WHERE n.n_regionkey = rs.r_regionkey
)
LEFT JOIN order_summary os ON os.o_custkey IN (
    SELECT c.c_custkey 
    FROM customer c 
    WHERE c.c_nationkey IN (
        SELECT n.n_nationkey 
        FROM nation n 
        WHERE n.n_regionkey = rs.r_regionkey
    )
)
LEFT JOIN line_item_summary lis ON lis.l_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    JOIN customer c ON o.o_custkey = c.c_custkey 
    WHERE c.c_nationkey IN (
        SELECT n.n_nationkey 
        FROM nation n 
        WHERE n.n_regionkey = rs.r_regionkey
    )
)
GROUP BY r.r_name, rs.nation_count, ss.total_acctbal, os.total_spent
HAVING COUNT(lis.l_orderkey) > 0
ORDER BY rs.nation_count DESC, total_supplier_acctbal DESC;
