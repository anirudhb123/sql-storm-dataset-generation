WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE p.p_size < 50
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_mktsegment = 'BUILDING'
    GROUP BY c.c_custkey, c.c_name
),
supply_data AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    s.s_name AS supplier,
    p.p_name AS part_name,
    p.p_retailprice,
    cp.c_name AS customer_name,
    co.total_orders,
    co.total_spent,
    sd.total_available,
    sd.avg_cost
FROM ranked_parts p
JOIN supply_data sd ON p.p_partkey = sd.ps_partkey
JOIN supplier s ON sd.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN customer_orders co ON co.total_spent > 10000
JOIN customer cp ON co.c_custkey = cp.c_custkey
WHERE p.rank <= 5
ORDER BY r.r_name, n.n_name, s.s_name, p.p_retailprice DESC;
