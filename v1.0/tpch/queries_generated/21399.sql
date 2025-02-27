WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_shippriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
),
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS parts_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
high_value_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        (SELECT AVG(o2.o_totalprice) 
         FROM orders o2 
         WHERE o2.o_custkey = c.c_custkey) AS avg_order_value
    FROM customer c
    WHERE c.c_acctbal > 10000
),
part_supplier_stats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS num_suppliers,
        SUM(ps.ps_availqty) AS total_available_qty,
        STRING_AGG(s.s_name, ', ') AS supplier_names
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT nc.n_nationkey) AS nations_count,
    SUM(CASE WHEN o.o_totalprice IS NULL THEN 0 ELSE o.o_totalprice END) AS total_revenue,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY customer_value) AS median_customer_value
FROM region r
LEFT JOIN nation nc ON r.r_regionkey = nc.n_regionkey
LEFT JOIN high_value_customers c ON nc.n_nationkey = c.c_nationkey
LEFT JOIN ranked_orders o ON c.c_custkey = o.o_custkey
LEFT JOIN (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS customer_value
    FROM lineitem l
    GROUP BY l.l_orderkey
) rev ON o.o_orderkey = rev.l_orderkey
GROUP BY r.r_name
HAVING COUNT(DISTINCT nc.n_nationkey) 
   + COALESCE(SUM(NULLIF(o.o_totalprice, 0)), 0) > 100000
ORDER BY r.r_name DESC;
