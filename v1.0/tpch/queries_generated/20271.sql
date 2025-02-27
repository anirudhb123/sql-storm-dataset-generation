WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
high_value_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
    HAVING COUNT(o.o_orderkey) > 5
),
discounted_parts AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        p.p_brand,
        p.p_container,
        ps.ps_availqty,
        CASE 
            WHEN p.p_retailprice > 100 THEN p.p_retailprice * 0.9
            ELSE p.p_retailprice
        END AS discounted_price
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty < (
        SELECT AVG(ps2.ps_availqty)
        FROM partsupp ps2
        WHERE ps2.ps_partkey = ps.ps_partkey
    )
)
SELECT 
    h.c_name,
    h.total_orders,
    r.o_orderkey,
    r.o_orderdate,
    r.total_revenue,
    d.p_name,
    d.discounted_price
FROM ranked_orders r
JOIN high_value_customers h ON r.o_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_custkey = h.c_custkey
) 
LEFT JOIN discounted_parts d ON r.o_orderkey = (
    SELECT l.l_orderkey
    FROM lineitem l
    WHERE l.l_partkey = d.ps_partkey
    ORDER BY l.l_extendedprice DESC
    LIMIT 1
)
WHERE r.revenue_rank = 1
AND d.discounted_price IS NOT NULL
ORDER BY h.c_name, r.total_revenue DESC;
