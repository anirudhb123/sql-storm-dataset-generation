WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal AS initial_balance,
        0 AS level
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL

    UNION ALL

    SELECT 
        c.c_custkey, 
        c.c_name,
        CASE 
            WHEN s.s_acctbal IS NOT NULL THEN s.s_acctbal + sh.initial_balance 
            ELSE sh.initial_balance 
        END AS initial_balance,
        level + 1
    FROM sales_hierarchy sh
    JOIN orders o ON sh.c_custkey = o.o_custkey
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    JOIN partsupp ps ON li.l_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE level < 10
),
total_sales AS (
    SELECT 
        c.c_custkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY c.c_custkey
),
avg_sales AS (
    SELECT 
        AVG(total_spent) AS avg_spent 
    FROM total_sales
),
region_supplier AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
)
SELECT 
    sh.c_name,
    sh.initial_balance,
    ts.total_spent,
    CASE 
        WHEN ts.total_spent > (SELECT avg_spent FROM avg_sales) THEN 'Above Average'
        ELSE 'Below Average'
    END AS spending_category,
    rs.region_name,
    rs.supplier_count
FROM sales_hierarchy sh
JOIN total_sales ts ON sh.c_custkey = ts.c_custkey
LEFT JOIN region_supplier rs ON rs.region_name = (
    SELECT r.r_name 
    FROM region r 
    JOIN nation n ON r.r_regionkey = n.n_regionkey 
    JOIN supplier s ON n.n_nationkey = s.s_nationkey 
    WHERE s.s_suppkey IN (SELECT DISTINCT ps.ps_suppkey FROM partsupp ps)
    LIMIT 1
)
ORDER BY sh.initial_balance DESC, ts.total_spent DESC;
