WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000  -- Initial level with account balance filter
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal  -- Assuming a hierarchical relationship on acct balance
),
total_sales AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY c.c_custkey, c.c_name
),
ranked_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ts.total_spent,
        ts.order_count,
        RANK() OVER (ORDER BY ts.total_spent DESC) AS rank
    FROM total_sales ts
    JOIN customer c ON ts.c_custkey = c.c_custkey
),
filtered_nations AS (
    SELECT n.n_nationkey, n.n_name
    FROM nation n
    WHERE n.n_regionkey IN (
        SELECT r.r_regionkey
        FROM region r
        WHERE r.r_name LIKE 'Asia%'
    )
)
SELECT 
    sh.s_suppkey,
    sh.s_name,
    fn.n_name AS nation,
    rc.rank,
    rc.total_spent,
    rc.order_count
FROM supplier_hierarchy sh
LEFT JOIN filtered_nations fn ON sh.s_nationkey = fn.n_nationkey
JOIN ranked_customers rc ON sh.s_nationkey = rc.c_custkey  -- Assuming nationality as customer key for bench marking
WHERE rc.rank <= 10  -- Top 10 customers based on spending
ORDER BY sh.s_suppkey;
