WITH ranked_lineitems AS (
    SELECT 
        l_orderkey,
        SUM(l_extendedprice * (1 - l_discount)) AS revenue,
        RANK() OVER (PARTITION BY l_orderkey ORDER BY SUM(l_extendedprice * (1 - l_discount)) DESC) AS revenue_rank
    FROM 
        lineitem
    GROUP BY 
        l_orderkey
),
top_revenue_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        n.n_name AS supplier_nation,
        c.c_name AS customer_name
    FROM 
        orders o
    JOIN 
        ranked_lineitems r ON o.o_orderkey = r.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        supplier s ON EXISTS (
            SELECT 1 
            FROM partsupp ps 
            WHERE ps.ps_partkey IN (
                SELECT l.l_partkey 
                FROM lineitem l 
                WHERE l.l_orderkey = o.o_orderkey
            ) AND ps.ps_suppkey = s.s_suppkey
        )
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        r.revenue_rank <= 5
)
SELECT 
    r.supplier_nation,
    COUNT(DISTINCT r.o_orderkey) AS number_of_orders,
    AVG(r.o_totalprice) AS avg_order_value,
    SUM(r.o_totalprice) AS total_revenue
FROM 
    top_revenue_orders r
GROUP BY 
    r.supplier_nation
ORDER BY 
    total_revenue DESC;
