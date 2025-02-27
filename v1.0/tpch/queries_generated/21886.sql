WITH RECURSIVE price_ranges AS (
    SELECT DISTINCT 
        CASE 
            WHEN p_retailprice < 10 THEN 'Cheap'
            WHEN p_retailprice BETWEEN 10 AND 50 THEN 'Affordable'
            WHEN p_retailprice BETWEEN 51 AND 100 THEN 'Expensive'
            ELSE 'Luxury'
        END AS price_category,
        p_partkey
    FROM part
),
supplier_stats AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS orders_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
partitioned_stats AS (
    SELECT
        c.c_custkey,
        COALESCE(total_spent, 0) AS total_spent,
        NTILE(4) OVER (ORDER BY COALESCE(total_spent, 0)) AS spending_quartile
    FROM customer_orders
    FULL OUTER JOIN customer c ON customer_orders.c_custkey = c.c_custkey
)
SELECT 
    pr.price_category,
    ns.n_name AS nation,
    ss.total_suppliers,
    ps.total_spent,
    ps.spending_quartile
FROM price_ranges pr
LEFT JOIN partsupp ps ON pr.p_partkey = ps.ps_partkey
JOIN supplier_stats ss ON ss.n_suppkey = ps.ps_suppkey
JOIN nation ns ON ns.n_nationkey = ss.s_nationkey
LEFT JOIN partitioned_stats ps ON ps.c_custkey = ns.n_nationkey
WHERE pr.price_category IS NOT NULL 
  AND ss.total_suppliers > (
    SELECT AVG(total_suppliers) FROM supplier_stats
)
ORDER BY pr.price_category, total_spent DESC
LIMIT 100;
