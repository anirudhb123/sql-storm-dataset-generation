WITH ranked_orders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderstatus, 
        c.c_name AS customer_name, 
        s.s_name AS supplier_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-10-01'
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, c.c_name, s.s_name
),
regional_summary AS (
    SELECT 
        n.n_name AS nation_name, 
        r.r_name AS region_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_price
    FROM ranked_orders o
    JOIN customer c ON o.customer_name = c.c_name
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_name, r.r_name
)
SELECT 
    r.region_name,
    r.nation_name, 
    r.order_count, 
    r.total_price, 
    COUNT(o.o_orderkey) OVER (PARTITION BY r.region_name) AS regional_order_total,
    SUM(o.total_revenue) OVER (PARTITION BY r.region_name) AS regional_revenue_total
FROM regional_summary r
JOIN ranked_orders o ON r.order_count = (SELECT COUNT(*) FROM ranked_orders WHERE o_orderkey = o.o_orderkey)
ORDER BY r.region_name, r.nation_name;
