WITH ranked_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        c.c_mktsegment,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rnk
    FROM customer c
    WHERE c.c_acctbal > 10000
),
top_customers AS (
    SELECT 
        rc.c_custkey,
        rc.c_name,
        rc.c_acctbal,
        rc.c_mktsegment
    FROM ranked_customers rc
    WHERE rc.rnk <= 10
),
order_summary AS (
    SELECT
        o.o_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM orders o
    GROUP BY o.o_custkey
),
customer_order_summary AS (
    SELECT
        tc.c_custkey,
        tc.c_name,
        tc.c_acctbal,
        tc.c_mktsegment,
        os.order_count,
        os.total_spent,
        os.avg_order_value
    FROM top_customers tc
    LEFT JOIN order_summary os ON tc.c_custkey = os.o_custkey
)
SELECT 
    cos.c_name,
    cos.c_acctbal,
    cos.c_mktsegment,
    cos.order_count,
    cos.total_spent,
    cos.avg_order_value,
    r.r_name AS region_name
FROM customer_order_summary cos
JOIN supplier s ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
JOIN part p ON p.p_partkey = ps.ps_partkey
JOIN region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = s.s_nationkey)
WHERE p.p_retailprice > 50.00
ORDER BY total_spent DESC;
