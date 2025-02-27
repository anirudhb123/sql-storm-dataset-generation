
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' AND 
        l.l_shipdate >= DATE '1997-01-01' AND 
        l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderpriority
),
top_revenue_orders AS (
    SELECT 
        r.o_orderkey,
        r.total_revenue,
        n.n_name AS nation,
        s.s_name AS supplier_name
    FROM 
        ranked_orders r
    JOIN 
        customer c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = r.o_orderkey)
    JOIN 
        supplier s ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps JOIN part p ON ps.ps_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = r.o_orderkey LIMIT 1))
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        r.order_rank <= 5
)
SELECT 
    nation, 
    COUNT(*) AS number_of_orders, 
    SUM(total_revenue) AS total_revenue_generated
FROM 
    top_revenue_orders
GROUP BY 
    nation
ORDER BY 
    total_revenue_generated DESC;
