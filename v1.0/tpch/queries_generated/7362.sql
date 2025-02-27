WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name
),
top_customers AS (
    SELECT 
        rn,
        c.c_name,
        r.r_name,
        sum(total_revenue) AS total_revenue
    FROM ranked_orders o
    JOIN nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_name = o.c_name)
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE rn <= 5
    GROUP BY rn, c.c_name, r.r_name
)
SELECT 
    r.r_name,
    SUM(tc.total_revenue) AS region_revenue,
    COUNT(DISTINCT tc.c_name) AS number_of_top_customers
FROM top_customers tc
JOIN region r ON tc.r_name = r.r_name
GROUP BY r.r_name
ORDER BY region_revenue DESC;
