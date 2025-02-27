WITH RECURSIVE price_comparison AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        'Initial' AS price_status
    FROM part p

    UNION ALL

    SELECT 
        ps.ps_partkey, 
        p.p_name, 
        ps.ps_supplycost AS p_retailprice, 
        'Adjusted' AS price_status
    FROM part p 
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_supplycost < p.p_retailprice
),
ranked_prices AS (
    SELECT 
        partkey, 
        p_name, 
        p_retailprice, 
        price_status,
        RANK() OVER (PARTITION BY price_status ORDER BY p_retailprice DESC) AS price_rank
    FROM price_comparison
),
customer_orders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
nation_analysis AS (
    SELECT 
        n.n_name, 
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
    HAVING COUNT(DISTINCT s.s_suppkey) > 5
)
SELECT 
    r.r_name, 
    np.p_name,
    np.p_retailprice,
    ca.c_name,
    ca.total_spent,
    na.supplier_count
FROM region r
LEFT JOIN ranked_prices np ON r.r_regionkey = np.p_partkey % (SELECT COUNT(DISTINCT p_partkey) FROM part)
JOIN customer_orders ca ON np.p_partkey = ca.o_orderkey % (SELECT COUNT(DISTINCT o_orderkey) FROM orders)
CROSS JOIN nation_analysis na
WHERE na.supplier_count IS NOT NULL
AND np.price_rank <= 10
ORDER BY np.p_retailprice DESC, ca.total_spent ASC
LIMIT 50;
