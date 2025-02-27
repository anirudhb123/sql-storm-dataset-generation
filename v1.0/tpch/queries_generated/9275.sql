WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
),
top_orders AS (
    SELECT 
        ranked_orders.o_orderkey,
        ranked_orders.o_totalprice,
        ranked_orders.o_orderdate,
        n.n_name AS nation_name,
        COUNT(l.l_orderkey) AS line_items,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        ranked_orders
    LEFT JOIN 
        lineitem l ON ranked_orders.o_orderkey = l.l_orderkey
    JOIN 
        nation n ON ranked_orders.c_nationkey = n.n_nationkey
    WHERE 
        ranked_orders.rank <= 5
    GROUP BY 
        ranked_orders.o_orderkey, ranked_orders.o_totalprice, ranked_orders.o_orderdate, n.n_name
)
SELECT 
    r.r_name AS region_name,
    SUM(to.net_revenue) AS total_revenue,
    COUNT(to.o_orderkey) AS total_orders
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    top_orders to ON n.n_nationkey = to.c_nationkey
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC;
