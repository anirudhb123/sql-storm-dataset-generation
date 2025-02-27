WITH RECURSIVE region_hierarchy AS (
    SELECT r_regionkey, r_name, r_comment, 0 AS depth
    FROM region
    WHERE r_regionkey = 1  -- Assuming 1 is a valid region key for starting point

    UNION ALL

    SELECT r.r_regionkey, r.r_name, r.r_comment, rh.depth + 1
    FROM region r
    JOIN region_hierarchy rh ON r.r_regionkey = rh.r_regionkey + 1  -- Recursive join condition, for simplicity
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
part_supplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 0
),
line_item_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
),
order_summary AS (
    SELECT o.o_orderkey, o.o_orderdate, COALESCE(ls.total_revenue, 0) AS revenue
    FROM orders o
    LEFT JOIN line_item_summary ls ON o.o_orderkey = ls.l_orderkey
    WHERE o.o_orderstatus = 'O'
),
final_summary AS (
    SELECT c.c_name, SUM(os.revenue) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(os.revenue) DESC) AS rev_rank
    FROM customer_summary cs
    JOIN order_summary os ON cs.c_custkey = os.o_orderkey
    JOIN customer c ON cs.c_custkey = c.c_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT rh.r_name, fs.c_name, fs.total_revenue
FROM final_summary fs
JOIN region_hierarchy rh ON fs.rev_rank = rh.depth
WHERE fs.total_revenue IS NOT NULL
ORDER BY fs.total_revenue DESC 
LIMIT 10;


