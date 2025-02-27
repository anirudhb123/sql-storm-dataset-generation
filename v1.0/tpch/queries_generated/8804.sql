WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
top_orders AS (
    SELECT 
        order_revenue.o_orderkey,
        order_revenue.o_orderdate,
        order_revenue.revenue
    FROM 
        ranked_orders order_revenue
    WHERE 
        order_revenue.rank <= 5
),
suppliers_with_parts AS (
    SELECT 
        ps.ps_partkey,
        p.p_brand,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, p.p_brand, s.s_name
)
SELECT 
    r.r_name,
    SUM(to.revenue) AS total_revenue,
    COUNT(swp.ps_partkey) AS total_parts,
    AVG(swp.total_supplycost) AS avg_supply_cost
FROM 
    top_orders to
JOIN 
    customer c ON to.o_orderkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    suppliers_with_parts swp ON swp.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = to.o_orderkey)
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC;
